import { Injectable, Logger } from '@nestjs/common';
import { NotificationType, OrderStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { FirebaseService } from './firebase.service';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private prisma: PrismaService,
    private firebaseService: FirebaseService,
  ) {}

  private statusMessages: Record<OrderStatus, { title: string; body: string }> =
    {
      PENDING: {
        title: 'Order Placed',
        body: 'Your order has been placed successfully.',
      },
      CONFIRMED: {
        title: 'Order Confirmed',
        body: 'Your order has been confirmed by our team.',
      },
      PACKED: {
        title: 'Order Packed',
        body: 'Your groceries are packed and ready.',
      },
      OUT_FOR_DELIVERY: {
        title: 'Out for Delivery',
        body: 'Your order is on the way!',
      },
      DELIVERED: {
        title: 'Delivered',
        body: 'Your order has been delivered. Enjoy!',
      },
      CANCELLED: {
        title: 'Order Cancelled',
        body: 'Your order has been cancelled.',
      },
    };

  async createNotification(data: {
    userId?: string;
    title: string;
    body: string;
    type?: NotificationType;
    data?: Record<string, unknown>;
    isGlobal?: boolean;
  }) {
    const notification = await this.prisma.notification.create({
      data: {
        userId: data.userId,
        title: data.title,
        body: data.body,
        type: data.type ?? NotificationType.SYSTEM,
        data: data.data as object,
        isGlobal: data.isGlobal ?? false,
      },
    });

    if (data.userId) {
      await this.sendPushNotification(data.userId, data.title, data.body, data.data);
    }

    return notification;
  }

  async sendOrderStatusNotification(
    userId: string,
    orderId: string,
    orderNumber: string,
    status: OrderStatus,
  ) {
    const msg = this.statusMessages[status];
    return this.createNotification({
      userId,
      title: msg.title,
      body: `${msg.body} Order #${orderNumber}`,
      type: NotificationType.ORDER,
      data: { orderId, orderNumber, status },
    });
  }

  private async sendPushNotification(
    userId: string,
    title: string,
    body: string,
    data?: Record<string, unknown>,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true },
    });

    if (!user?.fcmToken) return;

    const payload = Object.entries(data ?? {}).reduce(
      (acc, [k, v]) => {
        acc[k] = String(v);
        return acc;
      },
      {} as Record<string, string>,
    );

    const ok = await this.firebaseService.sendToDevice(
      user.fcmToken,
      title,
      body,
      payload,
    );

    await this.prisma.notificationDeliveryLog.create({
      data: {
        userId,
        title,
        status: ok ? 'sent' : 'failed',
        payload: data as object,
      },
    });
  }

  async getUserNotifications(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [data, total, unreadCount] = await Promise.all([
      this.prisma.notification.findMany({
        where: {
          OR: [{ userId }, { isGlobal: true }],
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.notification.count({
        where: { OR: [{ userId }, { isGlobal: true }] },
      }),
      this.prisma.notification.count({
        where: { userId, isRead: false },
      }),
    ]);

    return { data, total, unreadCount, page, limit };
  }

  async markAsRead(userId: string, notificationId: string) {
    return this.prisma.notification.updateMany({
      where: { id: notificationId, userId },
      data: { isRead: true },
    });
  }

  async markAllRead(userId: string) {
    return this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
  }

  async sendBroadcast(title: string, body: string, type?: NotificationType) {
    const notification = await this.createNotification({
      title,
      body,
      type: type ?? NotificationType.PROMOTION,
      isGlobal: true,
    });

    const users = await this.prisma.user.findMany({
      where: { fcmToken: { not: null }, isActive: true },
      select: { fcmToken: true },
    });

    const tokens = users
      .map((u) => u.fcmToken)
      .filter((t): t is string => !!t);

    const result = await this.firebaseService.sendToMany(tokens, title, body, {
      type: type ?? NotificationType.PROMOTION,
    });

    this.logger.log(
      `Broadcast push: ${result.success} sent, ${result.failure} failed`,
    );

    return { notification, push: result };
  }

  async sendPromotionalToUser(
    userId: string,
    title: string,
    body: string,
  ) {
    return this.createNotification({
      userId,
      title,
      body,
      type: NotificationType.PROMOTION,
    });
  }

  async sendDeliveryAssignedNotification(
    partnerUserId: string,
    customerUserId: string,
    orderId: string,
    orderNumber: string,
  ) {
    await this.createNotification({
      userId: partnerUserId,
      title: 'New delivery assigned',
      body: `Order #${orderNumber} has been assigned to you.`,
      type: NotificationType.ORDER,
      data: { orderId, orderNumber, event: 'assigned' },
    });

    await this.createNotification({
      userId: customerUserId,
      title: 'Delivery partner assigned',
      body: `A delivery partner is assigned for order #${orderNumber}.`,
      type: NotificationType.ORDER,
      data: { orderId, orderNumber, event: 'partner_assigned' },
    });
  }

  async sendDeliveryPartnerAcceptedNotification(
    customerUserId: string,
    orderId: string,
    orderNumber: string,
  ) {
    return this.createNotification({
      userId: customerUserId,
      title: 'Partner on the way soon',
      body: `Your delivery partner accepted order #${orderNumber}.`,
      type: NotificationType.ORDER,
      data: { orderId, orderNumber, event: 'partner_accepted' },
    });
  }

  async sendDeliveryOtpNotification(
    customerUserId: string,
    orderId: string,
    orderNumber: string,
    otp: string,
  ) {
    return this.createNotification({
      userId: customerUserId,
      title: 'Delivery OTP',
      body: `Share OTP ${otp} with your delivery partner for order #${orderNumber}.`,
      type: NotificationType.ORDER,
      data: { orderId, orderNumber, event: 'delivery_otp' },
    });
  }

  async sendOutForDeliveryPartnerNotification(
    customerUserId: string,
    orderId: string,
    orderNumber: string,
  ) {
    return this.createNotification({
      userId: customerUserId,
      title: 'Out for delivery',
      body: `Order #${orderNumber} is on the way!`,
      type: NotificationType.ORDER,
      data: { orderId, orderNumber, status: OrderStatus.OUT_FOR_DELIVERY },
    });
  }

  async sendDeliveryCompletedNotification(
    customerUserId: string,
    orderId: string,
    orderNumber: string,
  ) {
    return this.createNotification({
      userId: customerUserId,
      title: 'Delivered',
      body: `Order #${orderNumber} has been delivered successfully.`,
      type: NotificationType.ORDER,
      data: { orderId, orderNumber, status: OrderStatus.DELIVERED },
    });
  }
}
