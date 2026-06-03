import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  DeliveryAssignmentStatus,
  OrderStatus,
  UserRole,
} from '@prisma/client';
import { Inject } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { OrdersService } from '../orders/orders.service';
import { NotificationsService } from '../notifications/notifications.service';
import { DeliveryOtpService } from './delivery-otp.service';
import {
  paginate,
  paginatedResponse,
} from '../../common/dto/pagination.dto';
import { DELIVERY_REALTIME } from '../../common/realtime/delivery-realtime.interface';
import type { IDeliveryRealtime } from '../../common/realtime/delivery-realtime.interface';
import { LOCATION_TRACKER } from '../../common/location/location-tracker.interface';
import type { ILocationTracker } from '../../common/location/location-tracker.interface';

const ASSIGNABLE_ORDER_STATUSES: OrderStatus[] = [
  OrderStatus.CONFIRMED,
  OrderStatus.PACKED,
  OrderStatus.OUT_FOR_DELIVERY,
];

const ACTIVE_ASSIGNMENT_STATUSES: DeliveryAssignmentStatus[] = [
  DeliveryAssignmentStatus.ASSIGNED,
  DeliveryAssignmentStatus.PICKED,
  DeliveryAssignmentStatus.ON_THE_WAY,
];

@Injectable()
export class DeliveryAssignmentsService {
  private readonly assignmentInclude = {
    order: {
      include: {
        user: { select: { id: true, name: true, phone: true, fcmToken: true } },
        address: true,
        items: true,
        deliverySlot: true,
      },
    },
    partner: { select: { id: true, name: true, phone: true } },
  };

  constructor(
    private prisma: PrismaService,
    private ordersService: OrdersService,
    private notificationsService: NotificationsService,
    private deliveryOtpService: DeliveryOtpService,
    @Inject(DELIVERY_REALTIME) private realtime: IDeliveryRealtime,
    @Inject(LOCATION_TRACKER) private locationTracker: ILocationTracker,
  ) {}

  async assignOrder(orderId: string, deliveryPartnerId: string, notes?: string) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException('Order not found');

    if (!ASSIGNABLE_ORDER_STATUSES.includes(order.status)) {
      throw new BadRequestException(
        `Order must be CONFIRMED, PACKED, or OUT_FOR_DELIVERY to assign (current: ${order.status})`,
      );
    }

    await this.ensurePartner(deliveryPartnerId);

    const existing = await this.prisma.deliveryAssignment.findUnique({
      where: { orderId },
    });
    if (existing && ACTIVE_ASSIGNMENT_STATUSES.includes(existing.status)) {
      throw new BadRequestException('Order already has an active assignment');
    }

    if (existing) {
      await this.prisma.deliveryAssignment.delete({ where: { id: existing.id } });
    }

    const earning = await this.getPartnerEarningAmount();

    const assignment = await this.prisma.deliveryAssignment.create({
      data: {
        orderId,
        deliveryPartnerId,
        notes,
        earningAmount: earning,
        status: DeliveryAssignmentStatus.ASSIGNED,
      },
      include: this.assignmentInclude,
    });

    await this.notificationsService.sendDeliveryAssignedNotification(
      deliveryPartnerId,
      order.userId,
      order.id,
      order.orderNumber,
    );

    await this.realtime.emit({
      type: 'assignment.created',
      orderId,
      partnerId: deliveryPartnerId,
    });

    return this.serializeAssignment(assignment);
  }

  async reassignOrder(
    orderId: string,
    deliveryPartnerId: string,
    notes?: string,
  ) {
    const existing = await this.prisma.deliveryAssignment.findUnique({
      where: { orderId },
    });

    if (existing?.status === DeliveryAssignmentStatus.DELIVERED) {
      throw new BadRequestException('Cannot reassign a delivered order');
    }

    if (existing) {
      await this.prisma.deliveryAssignment.update({
        where: { id: existing.id },
        data: {
          status: DeliveryAssignmentStatus.FAILED,
          failureReason: 'Reassigned to another partner',
        },
      });
    }

    return this.assignOrder(orderId, deliveryPartnerId, notes);
  }

  async acceptOrder(partnerUserId: string, orderId: string) {
    const assignment = await this.getPartnerAssignment(partnerUserId, orderId);

    if (assignment.status !== DeliveryAssignmentStatus.ASSIGNED) {
      throw new BadRequestException('Order is not in ASSIGNED state');
    }

    const updated = await this.prisma.deliveryAssignment.update({
      where: { id: assignment.id },
      data: { acceptedAt: new Date() },
      include: this.assignmentInclude,
    });

    const order = updated.order;
    await this.notificationsService.sendDeliveryPartnerAcceptedNotification(
      order.userId,
      order.id,
      order.orderNumber,
    );

    return this.serializeAssignment(updated);
  }

  async pickOrder(partnerUserId: string, orderId: string) {
    const assignment = await this.getPartnerAssignment(partnerUserId, orderId);

    if (
      assignment.status !== DeliveryAssignmentStatus.ASSIGNED &&
      assignment.status !== DeliveryAssignmentStatus.PICKED
    ) {
      throw new BadRequestException('Invalid status for pick');
    }

    if (assignment.status === DeliveryAssignmentStatus.ASSIGNED) {
      await this.prisma.deliveryAssignment.update({
        where: { id: assignment.id },
        data: {
          status: DeliveryAssignmentStatus.PICKED,
          pickedAt: new Date(),
          acceptedAt: assignment.acceptedAt ?? new Date(),
        },
      });
    }

    const order = assignment.order;
    if (order.status === OrderStatus.CONFIRMED) {
      await this.ordersService.updateStatus(
        orderId,
        OrderStatus.PACKED,
        'Picked up by delivery partner',
      );
    }

    return this.getPartnerOrder(partnerUserId, orderId);
  }

  async startDelivery(partnerUserId: string, orderId: string) {
    const assignment = await this.getPartnerAssignment(partnerUserId, orderId);

    if (
      assignment.status !== DeliveryAssignmentStatus.PICKED &&
      assignment.status !== DeliveryAssignmentStatus.ASSIGNED
    ) {
      throw new BadRequestException('Order must be picked before starting delivery');
    }

    await this.prisma.deliveryAssignment.update({
      where: { id: assignment.id },
      data: {
        status: DeliveryAssignmentStatus.ON_THE_WAY,
        pickedAt: assignment.pickedAt ?? new Date(),
      },
    });

    await this.ordersService.updateStatus(
      orderId,
      OrderStatus.OUT_FOR_DELIVERY,
      'Out for delivery',
    );

    const otp = await this.deliveryOtpService.setOrderOtp(orderId);
    const orderMeta = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { id: true, userId: true, orderNumber: true },
    });

    if (orderMeta) {
      await this.notificationsService.sendDeliveryOtpNotification(
        orderMeta.userId,
        orderMeta.id,
        orderMeta.orderNumber,
        otp,
      );
    }

    await this.realtime.emit({
      type: 'assignment.updated',
      orderId,
      partnerId: partnerUserId,
      payload: { status: DeliveryAssignmentStatus.ON_THE_WAY },
    });

    return this.getPartnerOrder(partnerUserId, orderId);
  }

  async completeDelivery(partnerUserId: string, orderId: string, otp: string) {
    const assignment = await this.getPartnerAssignment(partnerUserId, orderId);

    if (assignment.status !== DeliveryAssignmentStatus.ON_THE_WAY) {
      throw new BadRequestException('Order must be on the way to complete delivery');
    }

    const valid = await this.deliveryOtpService.verifyOrderOtp(orderId, otp);
    if (!valid) {
      throw new BadRequestException('Invalid or expired delivery OTP');
    }

    const earning = Number(assignment.earningAmount ?? 0);

    await this.prisma.$transaction(async (tx) => {
      await tx.deliveryAssignment.update({
        where: { id: assignment.id },
        data: {
          status: DeliveryAssignmentStatus.DELIVERED,
          deliveredAt: new Date(),
        },
      });

      await tx.deliveryPartnerProfile.update({
        where: { userId: partnerUserId },
        data: {
          totalDeliveries: { increment: 1 },
          earnings: { increment: earning },
        },
      });
    });

    await this.ordersService.updateStatus(
      orderId,
      OrderStatus.DELIVERED,
      'Delivered with OTP verification',
    );

    await this.deliveryOtpService.clearOrderOtp(orderId);

    const order = assignment.order;
    await this.notificationsService.sendDeliveryCompletedNotification(
      order.userId,
      order.id,
      order.orderNumber,
    );

    await this.realtime.emit({
      type: 'order.delivered',
      orderId,
      partnerId: partnerUserId,
    });

    return this.getPartnerOrder(partnerUserId, orderId);
  }

  async failDelivery(
    partnerUserId: string,
    orderId: string,
    failureReason: string,
  ) {
    const assignment = await this.getPartnerAssignment(partnerUserId, orderId);

    if (assignment.status === DeliveryAssignmentStatus.DELIVERED) {
      throw new BadRequestException('Order already delivered');
    }

    await this.prisma.deliveryAssignment.update({
      where: { id: assignment.id },
      data: {
        status: DeliveryAssignmentStatus.FAILED,
        failureReason,
      },
    });

    return this.getPartnerOrder(partnerUserId, orderId);
  }

  async resendDeliveryOtp(partnerUserId: string, orderId: string) {
    const assignment = await this.getPartnerAssignment(partnerUserId, orderId);

    if (assignment.status !== DeliveryAssignmentStatus.ON_THE_WAY) {
      throw new BadRequestException('OTP can only be resent when order is on the way');
    }

    const otp = await this.deliveryOtpService.setOrderOtp(orderId);
    const order = assignment.order;

    await this.notificationsService.sendDeliveryOtpNotification(
      order.userId,
      order.id,
      order.orderNumber,
      otp,
    );

    return { success: true, message: 'OTP resent to customer' };
  }

  async listAssignedOrders(partnerUserId: string, page = 1, limit = 20) {
    const { take, skip } = paginate(page, limit);
    const where = {
      deliveryPartnerId: partnerUserId,
      status: { in: ACTIVE_ASSIGNMENT_STATUSES },
    };

    const [data, total] = await Promise.all([
      this.prisma.deliveryAssignment.findMany({
        where,
        skip,
        take,
        orderBy: { assignedAt: 'desc' },
        include: this.assignmentInclude,
      }),
      this.prisma.deliveryAssignment.count({ where }),
    ]);

    return paginatedResponse(
      data.map((a) => this.serializeAssignment(a)),
      total,
      page,
      limit,
    );
  }

  async listDeliveryHistory(partnerUserId: string, page = 1, limit = 20) {
    const { take, skip } = paginate(page, limit);
    const where = {
      deliveryPartnerId: partnerUserId,
      status: {
        in: [
          DeliveryAssignmentStatus.DELIVERED,
          DeliveryAssignmentStatus.FAILED,
        ],
      },
    };

    const [data, total] = await Promise.all([
      this.prisma.deliveryAssignment.findMany({
        where,
        skip,
        take,
        orderBy: { updatedAt: 'desc' },
        include: this.assignmentInclude,
      }),
      this.prisma.deliveryAssignment.count({ where }),
    ]);

    return paginatedResponse(
      data.map((a) => this.serializeAssignment(a)),
      total,
      page,
      limit,
    );
  }

  async getPartnerOrder(partnerUserId: string, orderId: string) {
    const assignment = await this.getPartnerAssignment(partnerUserId, orderId);
    return this.serializeAssignment(assignment);
  }

  async listPartnersForAdmin(filters?: {
    onlineOnly?: boolean;
    availableOnly?: boolean;
  }) {
    return this.prisma.deliveryPartnerProfile.findMany({
      where: {
        ...(filters?.onlineOnly ? { isOnline: true } : {}),
        ...(filters?.availableOnly ? { isAvailable: true } : {}),
        user: { role: UserRole.DELIVERY_PARTNER, isActive: true },
      },
      include: {
        user: { select: { id: true, name: true, phone: true, email: true } },
        _count: {
          select: {
            assignments: {
              where: { status: { in: ACTIVE_ASSIGNMENT_STATUSES } },
            },
          },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async getDeliveryAnalytics() {
    const [
      totalDelivered,
      totalFailed,
      activeAssignments,
      partnersOnline,
      avgDuration,
    ] = await Promise.all([
      this.prisma.deliveryAssignment.count({
        where: { status: DeliveryAssignmentStatus.DELIVERED },
      }),
      this.prisma.deliveryAssignment.count({
        where: { status: DeliveryAssignmentStatus.FAILED },
      }),
      this.prisma.deliveryAssignment.count({
        where: { status: { in: ACTIVE_ASSIGNMENT_STATUSES } },
      }),
      this.prisma.deliveryPartnerProfile.count({ where: { isOnline: true } }),
      this.prisma.deliveryAssignment.findMany({
        where: {
          status: DeliveryAssignmentStatus.DELIVERED,
          pickedAt: { not: null },
          deliveredAt: { not: null },
        },
        take: 100,
        orderBy: { deliveredAt: 'desc' },
        select: { pickedAt: true, deliveredAt: true },
      }),
    ]);

    let averageDeliveryMinutes = 0;
    if (avgDuration.length) {
      const totalMs = avgDuration.reduce((sum, a) => {
        if (!a.pickedAt || !a.deliveredAt) return sum;
        return sum + (a.deliveredAt.getTime() - a.pickedAt.getTime());
      }, 0);
      averageDeliveryMinutes = Math.round(
        totalMs / avgDuration.length / 60000,
      );
    }

    const partnerPerformance = await this.prisma.deliveryPartnerProfile.findMany({
      take: 10,
      orderBy: { totalDeliveries: 'desc' },
      include: {
        user: { select: { name: true, phone: true } },
      },
    });

    return {
      totalDelivered,
      totalFailed,
      activeAssignments,
      partnersOnline,
      averageDeliveryMinutes,
      partnerPerformance: partnerPerformance.map((p) => ({
        partnerId: p.userId,
        name: p.user.name,
        phone: p.user.phone,
        totalDeliveries: p.totalDeliveries,
        earnings: Number(p.earnings),
        rating: Number(p.rating),
        isOnline: p.isOnline,
      })),
    };
  }

  async recordPartnerLocation(
    partnerUserId: string,
    latitude: number,
    longitude: number,
  ) {
    await this.prisma.deliveryPartnerProfile.update({
      where: { userId: partnerUserId },
      data: { currentLatitude: latitude, currentLongitude: longitude },
    });

    await this.locationTracker.recordPartnerLocation({
      userId: partnerUserId,
      latitude,
      longitude,
    });

    if (this.realtime.isEnabled()) {
      await this.realtime.emit({
        type: 'location.updated',
        orderId: '',
        partnerId: partnerUserId,
        payload: { latitude, longitude },
      });
    }

    return { recorded: true, liveTracking: this.locationTracker.isLiveTrackingEnabled() };
  }

  private async getPartnerAssignment(partnerUserId: string, orderId: string) {
    const assignment = await this.prisma.deliveryAssignment.findFirst({
      where: { orderId, deliveryPartnerId: partnerUserId },
      include: this.assignmentInclude,
    });

    if (!assignment) {
      throw new ForbiddenException('You are not assigned to this order');
    }

    return assignment;
  }

  private async ensurePartner(userId: string) {
    const user = await this.prisma.user.findFirst({
      where: {
        id: userId,
        role: UserRole.DELIVERY_PARTNER,
        isActive: true,
        deletedAt: null,
      },
      include: { deliveryPartnerProfile: true },
    });

    if (!user) {
      throw new NotFoundException('Delivery partner not found');
    }

    if (!user.deliveryPartnerProfile) {
      await this.prisma.deliveryPartnerProfile.create({
        data: { userId },
      });
    }

    return user;
  }

  private async getPartnerEarningAmount(): Promise<number> {
    const settings = await this.prisma.deliverySettings.findFirst();
    return Number(settings?.partnerEarningPerDelivery ?? 25);
  }

  private serializeAssignment(assignment: Record<string, unknown>) {
    const order = assignment.order as Record<string, unknown> | undefined;
    const serializedOrder = order
      ? {
          ...order,
          subtotal: Number(order.subtotal),
          discountAmount: Number(order.discountAmount),
          deliveryFee: Number(order.deliveryFee),
          sameDayFee: Number(order.sameDayFee),
          totalAmount: Number(order.totalAmount),
          deliveryOtp: undefined,
          deliveryOtpExpiresAt: undefined,
        }
      : undefined;

    return {
      ...assignment,
      earningAmount: assignment.earningAmount
        ? Number(assignment.earningAmount)
        : null,
      order: serializedOrder,
    };
  }
}
