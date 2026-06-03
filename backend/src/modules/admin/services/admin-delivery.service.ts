import { Injectable, NotFoundException } from '@nestjs/common';
import { DeliveryType } from '@prisma/client';
import { PrismaService } from '../../../prisma/prisma.service';
import { DeliveryService } from '../../delivery/delivery.service';

@Injectable()
export class AdminDeliveryService {
  constructor(
    private prisma: PrismaService,
    private deliveryService: DeliveryService,
  ) {}

  getSettings() {
    return this.deliveryService.getSettings();
  }

  updateSettings(data: Record<string, unknown>) {
    return this.deliveryService.updateSettings(
      data as Parameters<DeliveryService['updateSettings']>[0],
    );
  }

  async listAllSlots() {
    return this.prisma.deliverySlot.findMany({
      orderBy: [{ deliveryType: 'asc' }, { startTime: 'asc' }],
    });
  }

  async createSlot(data: {
    name: string;
    startTime: string;
    endTime: string;
    deliveryType: DeliveryType;
    dayOffset?: number;
    maxOrders?: number;
    isActive?: boolean;
  }) {
    return this.prisma.deliverySlot.create({ data });
  }

  async updateSlot(id: string, data: Record<string, unknown>) {
    return this.prisma.deliverySlot.update({ where: { id }, data });
  }

  async deleteSlot(id: string) {
    return this.prisma.deliverySlot.delete({ where: { id } });
  }

  async listPincodes() {
    return this.prisma.serviceablePincode.findMany({
      orderBy: { pincode: 'asc' },
    });
  }

  async addPincode(pincode: string, city?: string) {
    return this.prisma.serviceablePincode.upsert({
      where: { pincode },
      update: { isActive: true, city },
      create: { pincode, city, isActive: true },
    });
  }

  async removePincode(id: string) {
    return this.prisma.serviceablePincode.delete({ where: { id } });
  }

  async slotAnalytics() {
    const slots = await this.prisma.deliverySlot.findMany({
      include: { _count: { select: { orders: true } } },
    });
    return slots.map((s) => ({
      id: s.id,
      name: s.name,
      deliveryType: s.deliveryType,
      orderCount: s._count.orders,
      maxOrders: s.maxOrders,
      isActive: s.isActive,
    }));
  }
}
