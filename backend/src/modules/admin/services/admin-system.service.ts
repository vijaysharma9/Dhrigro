import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { RedisService } from '../../../redis/redis.service';
import { QueuesService, QueueStats } from '../../../common/queues/queues.service';
import { SocketRealtimeService } from '../../../common/realtime/socket-realtime.service';

@Injectable()
export class AdminSystemService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private queues: QueuesService,
    private realtime: SocketRealtimeService,
  ) {}

  async getSystemHealth() {
    const dbStart = Date.now();
    let dbStatus = 'ok';
    let dbLatencyMs = 0;
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      dbLatencyMs = Date.now() - dbStart;
    } catch {
      dbStatus = 'error';
      dbLatencyMs = Date.now() - dbStart;
    }

    const redisReady = this.redis.isReady();
    const queueStats = await this.queues.getStats();

    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const [paymentFailuresToday, pendingOrders, activePartners] =
      await Promise.all([
        this.prisma.transaction.count({
          where: {
            paymentStatus: 'FAILED',
            createdAt: { gte: todayStart },
          },
        }),
        this.prisma.order.count({
          where: { status: { in: ['PENDING', 'CONFIRMED', 'PACKED'] } },
        }),
        this.prisma.deliveryPartnerProfile.count({
          where: { isOnline: true },
        }),
      ]);

    const failedJobs = queueStats.reduce((s: number, q: QueueStats) => s + q.failed, 0);
    const queueDepth = queueStats.reduce((s: number, q: QueueStats) => s + q.waiting, 0);

    return {
      api: { status: 'ok', latencyMs: dbLatencyMs },
      database: { status: dbStatus, latencyMs: dbLatencyMs },
      redis: {
        status: redisReady ? 'ok' : 'degraded',
        connected: redisReady,
      },
      websocket: {
        enabled: this.realtime.isEnabled(),
        connections: this.realtime.getConnectionCount(),
      },
      queues: {
        enabled: this.queues.isEnabled(),
        depth: queueDepth,
        failedJobs,
        stats: queueStats,
      },
      ops: {
        paymentFailuresToday,
        pendingOrders,
        activePartners,
      },
      timestamp: new Date().toISOString(),
    };
  }

  async getBiMetrics(fromDate?: string, toDate?: string) {
    const from = fromDate
      ? new Date(fromDate)
      : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const to = toDate ? new Date(toDate) : new Date();

    const orders = await this.prisma.order.findMany({
      where: { placedAt: { gte: from, lte: to }, status: { not: 'CANCELLED' } },
      select: {
        id: true,
        userId: true,
        totalAmount: true,
        placedAt: true,
        user: { select: { loyaltyPoints: true } },
      },
    });

    const userOrderCounts = new Map<string, number>();
    let totalRevenue = 0;
    for (const o of orders) {
      totalRevenue += Number(o.totalAmount);
      userOrderCounts.set(o.userId, (userOrderCounts.get(o.userId) ?? 0) + 1);
    }

    const repeatCustomers = [...userOrderCounts.values()].filter((c) => c > 1).length;
    const uniqueCustomers = userOrderCounts.size;
    const repeatRate =
      uniqueCustomers > 0 ? (repeatCustomers / uniqueCustomers) * 100 : 0;
    const avgOrderValue = orders.length > 0 ? totalRevenue / orders.length : 0;

    const categorySales = await this.prisma.orderItem.groupBy({
      by: ['productId'],
      where: { order: { placedAt: { gte: from, lte: to } } },
      _sum: { quantity: true, totalPrice: true },
      orderBy: { _sum: { totalPrice: 'desc' } },
      take: 5,
    });

    const productIds = categorySales.map((c: { productId: string }) => c.productId);
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } },
      select: { id: true, name: true, categoryId: true },
    });
    const productMap = new Map<string, { id: string; name: string }>(
      products.map((p) => [p.id, p]),
    );

    return {
      period: { from: from.toISOString(), to: to.toISOString() },
      orders: orders.length,
      revenue: totalRevenue,
      uniqueCustomers,
      repeatPurchaseRate: Math.round(repeatRate * 10) / 10,
      avgOrderValue: Math.round(avgOrderValue),
      avgCustomerLifetimeValue:
        uniqueCustomers > 0
          ? Math.round((totalRevenue / uniqueCustomers) * 100) / 100
          : 0,
      topProducts: categorySales.map((c: { productId: string; _sum: { quantity: number | null; totalPrice: unknown } }) => ({
        productId: c.productId,
        name: productMap.get(c.productId)?.name ?? 'Unknown',
        quantity: c._sum.quantity ?? 0,
        revenue: Number(c._sum.totalPrice ?? 0),
      })),
      insights: this.buildBiInsights(orders.length, repeatRate, totalRevenue),
    };
  }

  private buildBiInsights(
    orderCount: number,
    repeatRate: number,
    revenue: number,
  ): string[] {
    const insights: string[] = [];
    if (repeatRate >= 40) {
      insights.push(`Strong retention: ${repeatRate.toFixed(0)}% repeat purchase rate`);
    } else if (repeatRate < 20 && orderCount > 10) {
      insights.push('Retention opportunity: repeat rate below 20%');
    }
    if (revenue > 0) {
      insights.push(`Period revenue ₹${Math.round(revenue).toLocaleString('en-IN')}`);
    }
    if (orderCount === 0) {
      insights.push('No orders in selected period — widen date range');
    }
    return insights;
  }
}
