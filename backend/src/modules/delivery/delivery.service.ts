import { BadRequestException, Injectable } from '@nestjs/common';
import { DeliveryType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class DeliveryService {
  constructor(private prisma: PrismaService) {}

  async getSettings() {
    let settings = await this.prisma.deliverySettings.findFirst();
    if (!settings) {
      settings = await this.prisma.deliverySettings.create({ data: {} });
    }
    return {
      ...settings,
      sameDayFee: Number(settings.sameDayFee),
      defaultDeliveryFee: Number(settings.defaultDeliveryFee),
      minOrderAmount: Number(settings.minOrderAmount),
      freeDeliveryAbove: settings.freeDeliveryAbove
        ? Number(settings.freeDeliveryAbove)
        : null,
    };
  }

  async updateSettings(data: Partial<{
    sameDayEnabled: boolean;
    sameDayFee: number;
    defaultDeliveryFee: number;
    minOrderAmount: number;
    freeDeliveryAbove: number;
    morningSlotStart: string;
    morningSlotEnd: string;
  }>) {
    const existing = await this.getSettings();
    return this.prisma.deliverySettings.update({
      where: { id: existing.id },
      data,
    });
  }

  async getSlots(deliveryType?: DeliveryType) {
    return this.prisma.deliverySlot.findMany({
      where: {
        isActive: true,
        ...(deliveryType && { deliveryType }),
      },
      orderBy: { startTime: 'asc' },
    });
  }

  async checkPincode(pincode: string) {
    const record = await this.prisma.serviceablePincode.findFirst({
      where: { pincode, isActive: true },
    });
    return {
      serviceable: !!record,
      pincode,
      city: record?.city,
    };
  }

  async calculateFees(
    subtotal: number,
    deliveryType: DeliveryType = DeliveryType.NEXT_DAY_MORNING,
  ) {
    const settings = await this.getSettings();

    if (subtotal < Number(settings.minOrderAmount)) {
      throw new BadRequestException(
        `Minimum order amount is ₹${settings.minOrderAmount}`,
      );
    }

    let deliveryFee = Number(settings.defaultDeliveryFee);
    let sameDayFee = 0;

    if (
      settings.freeDeliveryAbove &&
      subtotal >= Number(settings.freeDeliveryAbove)
    ) {
      deliveryFee = 0;
    }

    if (deliveryType === DeliveryType.SAME_DAY) {
      if (!settings.sameDayEnabled) {
        throw new BadRequestException('Same day delivery is not available');
      }
      sameDayFee = Number(settings.sameDayFee);
    }

    return { deliveryFee, sameDayFee, settings };
  }

  async seedDefaultSlots() {
    const count = await this.prisma.deliverySlot.count();
    if (count > 0) return;

    await this.prisma.deliverySlot.createMany({
      data: [
        {
          name: 'Morning Delivery',
          startTime: '06:00',
          endTime: '09:00',
          deliveryType: DeliveryType.NEXT_DAY_MORNING,
          dayOffset: 1,
        },
        {
          name: 'Same Day Evening',
          startTime: '18:00',
          endTime: '21:00',
          deliveryType: DeliveryType.SAME_DAY,
          dayOffset: 0,
        },
      ],
    });
  }
}
