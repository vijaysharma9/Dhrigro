import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  DeliveryType,
  OrderStatus,
  PaymentMethod,
  PaymentStatus,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CartService } from '../cart/cart.service';
import { DeliveryService } from '../delivery/delivery.service';
import { NotificationsService } from '../notifications/notifications.service';
import { generateOrderNumber } from '../../common/utils/slug.util';
import {
  paginate,
  paginatedResponse,
  PaginationDto,
} from '../../common/dto/pagination.dto';
import { SocketRealtimeService } from '../../common/realtime/socket-realtime.service';
import { REALTIME_ROOMS } from '../../common/realtime/realtime-events';
import { AutomationService } from '../../common/automation/automation.service';

@Injectable()
export class OrdersService {
  constructor(
    private prisma: PrismaService,
    private cartService: CartService,
    private deliveryService: DeliveryService,
    private notificationsService: NotificationsService,
    private realtime: SocketRealtimeService,
    private automation: AutomationService,
  ) {}

  async placeOrder(
    userId: string,
    data: {
      addressId: string;
      deliverySlotId?: string;
      deliveryType?: DeliveryType;
      paymentMethod?: PaymentMethod;
      deliveryInstructions?: string;
    },
  ) {
    const deliveryType =
      data.deliveryType ?? DeliveryType.NEXT_DAY_MORNING;

    const address = await this.prisma.address.findFirst({
      where: { id: data.addressId, userId },
    });
    if (!address) throw new NotFoundException('Address not found');

    const pincodeCheck = await this.deliveryService.checkPincode(
      address.pincode,
    );
    if (!pincodeCheck.serviceable) {
      throw new BadRequestException('Delivery not available for this pincode');
    }

    const preCart = await this.cartService.getCart(userId);
    const fees = await this.deliveryService.calculateFees(
      preCart.subtotal,
      deliveryType,
    );

    const cart = await this.cartService.getCart(
      userId,
      fees.deliveryFee,
      fees.sameDayFee,
    );
    const activeItems = cart.items.filter(
      (i: { savedForLater: boolean }) => !i.savedForLater,
    );

    if (!activeItems.length) {
      throw new BadRequestException('Cart is empty');
    }

    const orderNumber = generateOrderNumber();
    const paymentMethod = data.paymentMethod ?? PaymentMethod.COD;
    const isOnlinePayment = paymentMethod === PaymentMethod.RAZORPAY;
    const paymentStatus = PaymentStatus.PENDING;

    const totalAmount =
      Number(cart.subtotal) -
      Number(cart.discountAmount) +
      fees.deliveryFee +
      fees.sameDayFee;

    const order = await this.prisma.$transaction(async (tx) => {
      const created = await tx.order.create({
        data: {
          orderNumber,
          userId,
          addressId: data.addressId,
          deliverySlotId: data.deliverySlotId,
          couponId: cart.coupon?.id,
          deliveryType,
          paymentMethod,
          paymentStatus,
          subtotal: cart.subtotal,
          discountAmount: cart.discountAmount,
          deliveryFee: fees.deliveryFee,
          sameDayFee: fees.sameDayFee,
          totalAmount,
          deliveryInstructions: data.deliveryInstructions,
          items: {
            create: activeItems.map((item) => ({
                productId: item.productId,
                variantId: item.variantId ?? undefined,
                productName: item.product.name,
                variantLabel: item.variant?.label ?? undefined,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                totalPrice: item.unitPrice * item.quantity,
              })),
          },
          statusLogs: {
            create: { status: OrderStatus.PENDING, note: 'Order placed' },
          },
        },
        include: { items: true, address: true, deliverySlot: true },
      });

      if (!isOnlinePayment) {
        if (cart.coupon?.id) {
          await tx.coupon.update({
            where: { id: cart.coupon.id },
            data: { usedCount: { increment: 1 } },
          });
        }

        await tx.cartItem.deleteMany({
          where: {
            cartId: cart.id,
            savedForLater: false,
          },
        });
      }

      return created;
    });

    await this.notificationsService.sendOrderStatusNotification(
      userId,
      order.id,
      orderNumber,
      OrderStatus.PENDING,
    );

    await this.realtime.publish({
      type: 'order_created',
      room: REALTIME_ROOMS.admin,
      payload: { orderId: order.id, orderNumber, userId },
    });
    await this.automation.onOrderCreated(order.id, userId);

    return {
      ...order,
      totalAmount,
      requiresPayment: isOnlinePayment,
      paymentMethod,
    };
  }

  async getUserOrders(userId: string, pagination: PaginationDto) {
    const { page = 1, limit = 20 } = pagination;
    const { take, skip } = paginate(page, limit);

    const [data, total] = await Promise.all([
      this.prisma.order.findMany({
        where: { userId },
        skip,
        take,
        orderBy: { placedAt: 'desc' },
        include: {
          items: true,
          address: true,
          deliverySlot: true,
        },
      }),
      this.prisma.order.count({ where: { userId } }),
    ]);

    return paginatedResponse(data, total, page, limit);
  }

  async getOrder(userId: string, orderId: string, isAdmin = false) {
    const order = await this.prisma.order.findFirst({
      where: {
        id: orderId,
        ...(isAdmin ? {} : { userId }),
      },
      include: {
        items: { include: { product: true } },
        address: true,
        deliverySlot: true,
        statusLogs: { orderBy: { createdAt: 'asc' } },
        transactions: true,
      },
    });

    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  async updateStatus(
    orderId: string,
    status: OrderStatus,
    note?: string,
    cancelledReason?: string,
  ) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
    });
    if (!order) throw new NotFoundException('Order not found');

    const timestamps: Record<string, Date> = {};
    if (status === OrderStatus.CONFIRMED) timestamps.confirmedAt = new Date();
    if (status === OrderStatus.PACKED) timestamps.packedAt = new Date();
    if (status === OrderStatus.OUT_FOR_DELIVERY)
      timestamps.outForDeliveryAt = new Date();
    if (status === OrderStatus.DELIVERED) timestamps.deliveredAt = new Date();
    if (status === OrderStatus.CANCELLED) {
      timestamps.cancelledAt = new Date();
    }

    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: {
        status,
        cancelledReason,
        ...timestamps,
        statusLogs: {
          create: { status, note },
        },
      },
      include: { statusLogs: true },
    });

    await this.notificationsService.sendOrderStatusNotification(
      order.userId,
      order.id,
      order.orderNumber,
      status,
    );

    await this.realtime.publish({
      type: 'order_updated',
      room: REALTIME_ROOMS.admin,
      payload: { orderId, status, orderNumber: order.orderNumber },
    });

    return updated;
  }

  async reorder(userId: string, orderId: string) {
    const order = await this.getOrder(userId, orderId);
    for (const item of order.items) {
      await this.cartService.addItem(
        userId,
        item.productId,
        item.quantity,
        item.variantId ?? undefined,
      );
    }
    return this.cartService.getCart(userId);
  }

  async getAllOrders(pagination: PaginationDto, status?: OrderStatus) {
    const { page = 1, limit = 20 } = pagination;
    const { take, skip } = paginate(page, limit);

    const where = status ? { status } : {};

    const [data, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        skip,
        take,
        orderBy: { placedAt: 'desc' },
        include: {
          user: { select: { name: true, phone: true, email: true } },
          items: true,
          address: true,
        },
      }),
      this.prisma.order.count({ where }),
    ]);

    return paginatedResponse(data, total, page, limit);
  }
}
