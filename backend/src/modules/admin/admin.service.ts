import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OrderStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CacheService } from '../../redis/cache.service';

@Injectable()
export class AdminService {
  constructor(
    private prisma: PrismaService,
    private cache: CacheService,
    private configService: ConfigService,
  ) {}

  async getDashboardStats() {
    const ttl = this.configService.get<number>('cache.dashboardTtl') || 60;
    return this.cache.wrap('admin:dashboard', ttl, () =>
      this.computeDashboardStats(),
    );
  }

  private async computeDashboardStats() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const lowStockThreshold = 10;

    const [
      totalOrders,
      ordersToday,
      revenueTodayAgg,
      pendingOrders,
      pendingDeliveries,
      totalCustomers,
      activeUsersToday,
      revenueAgg,
      ordersByStatus,
      recentOrders,
      lowStockProducts,
      topProducts,
    ] = await Promise.all([
      this.prisma.order.count(),
      this.prisma.order.count({ where: { placedAt: { gte: today } } }),
      this.prisma.order.aggregate({
        where: {
          placedAt: { gte: today, lt: tomorrow },
          status: { not: OrderStatus.CANCELLED },
        },
        _sum: { totalAmount: true },
      }),
      this.prisma.order.count({
        where: {
          status: {
            in: [
              OrderStatus.PENDING,
              OrderStatus.CONFIRMED,
              OrderStatus.PACKED,
            ],
          },
        },
      }),
      this.prisma.order.count({
        where: {
          status: {
            in: [OrderStatus.CONFIRMED, OrderStatus.PACKED, OrderStatus.OUT_FOR_DELIVERY],
          },
        },
      }),
      this.prisma.user.count({
        where: { role: 'CUSTOMER', deletedAt: null },
      }),
      this.prisma.user.count({
        where: {
          role: 'CUSTOMER',
          orders: { some: { placedAt: { gte: today } } },
        },
      }),
      this.prisma.order.aggregate({
        _sum: { totalAmount: true },
        where: { status: { not: OrderStatus.CANCELLED } },
      }),
      this.prisma.order.groupBy({
        by: ['status'],
        _count: { status: true },
      }),
      this.prisma.order.findMany({
        take: 10,
        orderBy: { placedAt: 'desc' },
        include: {
          user: { select: { name: true, phone: true } },
          items: { take: 3 },
        },
      }),
      this.prisma.product.findMany({
        where: { deletedAt: null, stock: { lte: lowStockThreshold } },
        take: 8,
        orderBy: { stock: 'asc' },
        select: { id: true, name: true, stock: true, images: true },
      }),
      this.prisma.orderItem.groupBy({
        by: ['productId', 'productName'],
        _sum: { quantity: true },
        orderBy: { _sum: { quantity: 'desc' } },
        take: 5,
      }),
    ]);

    const last7Days = await this.getSalesLast7Days();
    const last30Days = await this.getMonthlyRevenue();

    const [
      activeDeliveries,
      partnersOnline,
      deliveriesToday,
    ] = await Promise.all([
      this.prisma.deliveryAssignment.count({
        where: {
          status: {
            in: ['ASSIGNED', 'PICKED', 'ON_THE_WAY'],
          },
        },
      }),
      this.prisma.deliveryPartnerProfile.count({ where: { isOnline: true } }),
      this.prisma.deliveryAssignment.count({
        where: {
          status: 'DELIVERED',
          deliveredAt: { gte: today },
        },
      }),
    ]);

    return {
      totalRevenue: Number(revenueAgg._sum.totalAmount || 0),
      revenueToday: Number(revenueTodayAgg._sum.totalAmount || 0),
      totalOrders,
      ordersToday,
      pendingOrders,
      pendingDeliveries,
      totalCustomers,
      activeUsersToday,
      ordersByStatus,
      salesLast7Days: last7Days,
      salesLast30Days: last30Days,
      recentOrders: recentOrders.map((o) => ({
        ...o,
        totalAmount: Number(o.totalAmount),
      })),
      lowStockProducts,
      topProducts: topProducts.map((p) => ({
        productId: p.productId,
        productName: p.productName,
        quantitySold: p._sum.quantity,
      })),
      deliveryOps: {
        activeDeliveries,
        partnersOnline,
        deliveriesToday,
      },
    };
  }

  private async getSalesLast7Days() {
    const days: { date: string; revenue: number; orders: number }[] = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      date.setHours(0, 0, 0, 0);
      const nextDate = new Date(date);
      nextDate.setDate(nextDate.getDate() + 1);

      const agg = await this.prisma.order.aggregate({
        where: {
          placedAt: { gte: date, lt: nextDate },
          status: { not: OrderStatus.CANCELLED },
        },
        _sum: { totalAmount: true },
        _count: true,
      });

      days.push({
        date: date.toISOString().split('T')[0],
        revenue: Number(agg._sum.totalAmount || 0),
        orders: agg._count,
      });
    }
    return days;
  }

  private async getMonthlyRevenue() {
    const days: { date: string; revenue: number }[] = [];
    for (let i = 29; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      date.setHours(0, 0, 0, 0);
      const next = new Date(date);
      next.setDate(next.getDate() + 1);
      const agg = await this.prisma.order.aggregate({
        where: {
          placedAt: { gte: date, lt: next },
          status: { not: OrderStatus.CANCELLED },
        },
        _sum: { totalAmount: true },
      });
      days.push({
        date: date.toISOString().split('T')[0],
        revenue: Number(agg._sum.totalAmount || 0),
      });
    }
    return days;
  }
}
