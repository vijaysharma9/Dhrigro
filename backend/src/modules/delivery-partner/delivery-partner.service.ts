import { Injectable, NotFoundException } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { DeliveryAssignmentsService } from '../delivery-assignments/delivery-assignments.service';
import {
  UpdateAvailabilityDto,
  UpdateDeliveryProfileDto,
} from './dto/delivery-partner.dto';

@Injectable()
export class DeliveryPartnerService {
  constructor(
    private prisma: PrismaService,
    private assignmentsService: DeliveryAssignmentsService,
  ) {}

  async getOrCreateProfile(userId: string) {
    const user = await this.prisma.user.findFirst({
      where: {
        id: userId,
        role: UserRole.DELIVERY_PARTNER,
        isActive: true,
      },
    });

    if (!user) {
      throw new NotFoundException('Delivery partner account not found');
    }

    let profile = await this.prisma.deliveryPartnerProfile.findUnique({
      where: { userId },
    });

    if (!profile) {
      profile = await this.prisma.deliveryPartnerProfile.create({
        data: { userId },
      });
    }

    return {
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        role: user.role,
      },
      profile: {
        ...profile,
        rating: Number(profile.rating),
        earnings: Number(profile.earnings),
      },
    };
  }

  async updateProfile(userId: string, dto: UpdateDeliveryProfileDto) {
    if (dto.name) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { name: dto.name },
      });
    }

    await this.prisma.deliveryPartnerProfile.update({
      where: { userId },
      data: {
        vehicleType: dto.vehicleType,
        licenseNumber: dto.licenseNumber,
      },
    });

    return this.getOrCreateProfile(userId);
  }

  async updateAvailability(userId: string, dto: UpdateAvailabilityDto) {
    await this.prisma.deliveryPartnerProfile.update({
      where: { userId },
      data: {
        ...(dto.isOnline !== undefined ? { isOnline: dto.isOnline } : {}),
        ...(dto.isAvailable !== undefined
          ? { isAvailable: dto.isAvailable }
          : {}),
      },
    });

    return this.getOrCreateProfile(userId);
  }

  async getEarnings(userId: string) {
    const profile = await this.prisma.deliveryPartnerProfile.findUnique({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    const recent = await this.prisma.deliveryAssignment.findMany({
      where: {
        deliveryPartnerId: userId,
        status: 'DELIVERED',
      },
      orderBy: { deliveredAt: 'desc' },
      take: 30,
      select: {
        id: true,
        orderId: true,
        deliveredAt: true,
        earningAmount: true,
        order: { select: { orderNumber: true, totalAmount: true } },
      },
    });

    const last7Days = await this.prisma.deliveryAssignment.groupBy({
      by: ['status'],
      where: {
        deliveryPartnerId: userId,
        deliveredAt: {
          gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
        },
        status: 'DELIVERED',
      },
      _count: true,
      _sum: { earningAmount: true },
    });

    return {
      totalEarnings: Number(profile.earnings),
      totalDeliveries: profile.totalDeliveries,
      rating: Number(profile.rating),
      recentDeliveries: recent.map((r) => ({
        ...r,
        earningAmount: Number(r.earningAmount ?? 0),
        order: {
          ...r.order,
          totalAmount: Number(r.order.totalAmount),
        },
      })),
      last7DaysDelivered: last7Days[0]?._count ?? 0,
      last7DaysEarnings: Number(last7Days[0]?._sum.earningAmount ?? 0),
    };
  }

  recordLocation(
    userId: string,
    latitude: number,
    longitude: number,
  ) {
    return this.assignmentsService.recordPartnerLocation(
      userId,
      latitude,
      longitude,
    );
  }
}
