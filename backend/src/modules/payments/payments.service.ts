import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  OrderStatus,
  PaymentMethod,
  PaymentStatus,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { RazorpayService } from './razorpay.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PaymentAuditService } from './payment-audit.service';
import { PaymentIdempotencyService } from './payment-idempotency.service';
@Injectable()
export class PaymentsService {
  constructor(
    private prisma: PrismaService,
    private razorpayService: RazorpayService,
    private notificationsService: NotificationsService,
    private paymentAudit: PaymentAuditService,
    private idempotency: PaymentIdempotencyService,
  ) {}

  async createRazorpayOrder(userId: string, orderId: string) {
    const order = await this.prisma.order.findFirst({
      where: {
        id: orderId,
        userId,
        paymentMethod: PaymentMethod.RAZORPAY,
      },
      include: { user: { select: { name: true, email: true, phone: true } } },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    if (order.paymentStatus === PaymentStatus.PAID) {
      throw new BadRequestException('Order is already paid');
    }

    if (order.status === OrderStatus.CANCELLED) {
      throw new BadRequestException('Order is cancelled');
    }

    const amount = Number(order.totalAmount);

    const razorpayOrder = await this.razorpayService.createOrder(
      amount,
      order.orderNumber,
      {
        orderId: order.id,
        userId: order.userId,
      },
    );

    await this.prisma.order.update({
      where: { id: order.id },
      data: { razorpayOrderId: razorpayOrder.id },
    });

    await this.paymentAudit.log({
      orderId: order.id,
      userId,
      eventType: 'RAZORPAY_ORDER_CREATED',
      status: 'PENDING',
      source: 'api',
      payload: { razorpayOrderId: razorpayOrder.id },
    });

    return {
      keyId: this.razorpayService.getKeyId(),
      razorpayOrderId: razorpayOrder.id,
      amount: razorpayOrder.amount,
      currency: razorpayOrder.currency,
      orderId: order.id,
      orderNumber: order.orderNumber,
      prefill: {
        name: order.user.name ?? '',
        email: order.user.email ?? '',
        contact: order.user.phone ?? '',
      },
    };
  }

  async verifyRazorpayPayment(
    userId: string,
    data: {
      orderId: string;
      razorpayOrderId: string;
      razorpayPaymentId: string;
      razorpaySignature: string;
    },
  ) {
    const valid = this.razorpayService.verifyPaymentSignature(
      data.razorpayOrderId,
      data.razorpayPaymentId,
      data.razorpaySignature,
    );

    if (!valid) {
      await this.paymentAudit.log({
        orderId: data.orderId,
        userId,
        eventType: 'VERIFY_FAILED',
        status: 'FAILED',
        source: 'client_verify',
      });
      throw new BadRequestException('Invalid payment signature');
    }

    return this.markOrderPaid(data.orderId, userId, {
      razorpayOrderId: data.razorpayOrderId,
      razorpayPaymentId: data.razorpayPaymentId,
      source: 'client_verify',
    });
  }

  async handleWebhook(rawBody: Buffer, signature: string) {
    const valid = this.razorpayService.verifyWebhookSignature(
      rawBody,
      signature,
    );
    if (!valid) {
      throw new BadRequestException('Invalid webhook signature');
    }

    const event = JSON.parse(rawBody.toString('utf8'));
    const eventType = event.event as string;
    const eventId = (event.id as string) || `${eventType}:${event.created_at}`;

    const isNew = await this.idempotency.registerWebhookEvent(eventId);
    if (!isNew) {
      await this.paymentAudit.log({
        eventType: 'WEBHOOK_REPLAY',
        status: 'SKIPPED',
        source: 'webhook',
        payload: { eventId, eventType },
      });
      return { received: true, replay: true };
    }

    if (eventType === 'payment.captured') {
      const payment = event.payload?.payment?.entity;
      if (!payment) return { received: true };

      const razorpayOrderId = payment.order_id as string;
      const razorpayPaymentId = payment.id as string;

      const order = await this.prisma.order.findFirst({
        where: { razorpayOrderId },
      });

      if (order && order.paymentStatus !== PaymentStatus.PAID) {
        await this.markOrderPaid(order.id, order.userId, {
          razorpayOrderId,
          razorpayPaymentId,
          source: 'webhook',
        });
      }
    }

    if (eventType === 'payment.failed') {
      const payment = event.payload?.payment?.entity;
      const razorpayOrderId = payment?.order_id as string | undefined;
      if (razorpayOrderId) {
        await this.prisma.order.updateMany({
          where: {
            razorpayOrderId,
            paymentStatus: PaymentStatus.PENDING,
          },
          data: { paymentStatus: PaymentStatus.FAILED },
        });
      }
    }

    return { received: true };
  }

  async markPaymentFailed(userId: string, orderId: string, reason?: string) {
    const order = await this.prisma.order.findFirst({
      where: { id: orderId, userId, paymentMethod: PaymentMethod.RAZORPAY },
    });
    if (!order) throw new NotFoundException('Order not found');

    await this.prisma.order.update({
      where: { id: orderId },
      data: {
        paymentStatus: PaymentStatus.FAILED,
        cancelledReason: reason ?? 'Payment failed or cancelled',
      },
    });

    await this.prisma.transaction.create({
      data: {
        orderId,
        amount: order.totalAmount,
        paymentMethod: PaymentMethod.RAZORPAY,
        paymentStatus: PaymentStatus.FAILED,
        gateway: 'razorpay',
        metadata: { reason },
      },
    });

    return { message: 'Payment marked as failed', orderId };
  }

  private async markOrderPaid(
    orderId: string,
    userId: string,
    payment: {
      razorpayOrderId: string;
      razorpayPaymentId: string;
      source: string;
    },
  ) {
    const order = await this.prisma.order.findFirst({
      where: { id: orderId, userId },
    });

    if (!order) throw new NotFoundException('Order not found');

    if (order.paymentStatus === PaymentStatus.PAID) {
      return { message: 'Already paid', order };
    }

    await this.idempotency.acquirePaymentLock(orderId);

    try {
      const updated = await this.markOrderPaidTransaction(
        order,
        orderId,
        userId,
        payment,
      );
      await this.paymentAudit.log({
        orderId,
        userId,
        eventType: 'PAYMENT_CAPTURED',
        status: 'PAID',
        source: payment.source,
        payload: {
          razorpayOrderId: payment.razorpayOrderId,
          razorpayPaymentId: payment.razorpayPaymentId,
        },
      });
      return updated;
    } finally {
      await this.idempotency.releasePaymentLock(orderId);
    }
  }

  private async markOrderPaidTransaction(
    order: Awaited<ReturnType<typeof this.prisma.order.findFirst>>,
    orderId: string,
    userId: string,
    payment: {
      razorpayOrderId: string;
      razorpayPaymentId: string;
      source: string;
    },
  ) {
    if (!order) throw new NotFoundException('Order not found');
    const updated = await this.prisma.$transaction(async (tx) => {
      const updatedOrder = await tx.order.update({
        where: { id: orderId },
        data: {
          paymentStatus: PaymentStatus.PAID,
          razorpayOrderId: payment.razorpayOrderId,
          razorpayPaymentId: payment.razorpayPaymentId,
          status:
            order.status === OrderStatus.PENDING
              ? OrderStatus.CONFIRMED
              : order.status,
          confirmedAt:
            order.status === OrderStatus.PENDING ? new Date() : order.confirmedAt,
        },
      });

      await tx.transaction.create({
        data: {
          orderId,
          amount: order.totalAmount,
          paymentMethod: PaymentMethod.RAZORPAY,
          paymentStatus: PaymentStatus.PAID,
          gateway: 'razorpay',
          gatewayOrderId: payment.razorpayOrderId,
          gatewayPaymentId: payment.razorpayPaymentId,
          metadata: { source: payment.source },
        },
      });

      if (order.couponId) {
        await tx.coupon.update({
          where: { id: order.couponId },
          data: { usedCount: { increment: 1 } },
        });
      }

      const cart = await tx.cart.findUnique({ where: { userId } });
      if (cart) {
        await tx.cartItem.deleteMany({
          where: { cartId: cart.id, savedForLater: false },
        });
        await tx.cart.update({
          where: { id: cart.id },
          data: { couponId: null },
        });
      }

      if (order.status === OrderStatus.PENDING) {
        await tx.orderStatusLog.create({
          data: {
            orderId,
            status: OrderStatus.CONFIRMED,
            note: 'Payment received — order confirmed',
          },
        });
      }

      return updatedOrder;
    });

    await this.notificationsService.sendOrderStatusNotification(
      userId,
      orderId,
      order.orderNumber,
      OrderStatus.CONFIRMED,
    );

    return {
      success: true,
      message: 'Payment verified successfully',
      order: updated,
    };
  }
}
