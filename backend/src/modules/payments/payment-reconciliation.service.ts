import { Injectable } from '@nestjs/common';
import { PaymentStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class PaymentReconciliationService {
  constructor(private prisma: PrismaService) {}

  async getPendingPayments(olderThanMinutes = 30) {
    const cutoff = new Date(Date.now() - olderThanMinutes * 60 * 1000);
    return this.prisma.order.findMany({
      where: {
        paymentMethod: 'RAZORPAY',
        paymentStatus: PaymentStatus.PENDING,
        placedAt: { lt: cutoff },
        status: { not: 'CANCELLED' },
      },
      select: {
        id: true,
        orderNumber: true,
        userId: true,
        totalAmount: true,
        razorpayOrderId: true,
        placedAt: true,
      },
      take: 100,
    });
  }

  async summary(from: Date, to: Date) {
    const [paid, failed, pending] = await Promise.all([
      this.prisma.transaction.count({
        where: {
          paymentStatus: PaymentStatus.PAID,
          createdAt: { gte: from, lte: to },
        },
      }),
      this.prisma.transaction.count({
        where: {
          paymentStatus: PaymentStatus.FAILED,
          createdAt: { gte: from, lte: to },
        },
      }),
      this.prisma.order.count({
        where: {
          paymentStatus: PaymentStatus.PENDING,
          placedAt: { gte: from, lte: to },
        },
      }),
    ]);

    const revenue = await this.prisma.transaction.aggregate({
      where: {
        paymentStatus: PaymentStatus.PAID,
        createdAt: { gte: from, lte: to },
      },
      _sum: { amount: true },
    });

    return {
      paidCount: paid,
      failedCount: failed,
      pendingOrders: pending,
      revenue: Number(revenue._sum.amount || 0),
      from,
      to,
    };
  }
}
