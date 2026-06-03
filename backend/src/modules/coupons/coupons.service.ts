import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class CouponsService {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    return this.prisma.coupon.findMany({ orderBy: { createdAt: 'desc' } });
  }

  async create(data: {
    code: string;
    description?: string;
    discountType?: string;
    discountValue: number;
    minOrderAmount?: number;
    maxDiscount?: number;
    usageLimit?: number;
    expiresAt?: Date;
  }) {
    return this.prisma.coupon.create({
      data: { ...data, code: data.code.toUpperCase() },
    });
  }

  async update(id: string, data: Record<string, unknown>) {
    return this.prisma.coupon.update({ where: { id }, data });
  }

  async remove(id: string) {
    return this.prisma.coupon.delete({ where: { id } });
  }
}
