import { Injectable } from '@nestjs/common';
import { OrderStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../../prisma/prisma.service';
import { toCsv } from '../../../common/utils/csv.util';
import { AdminReportsQueryDto } from '../dto/admin-query.dto';

@Injectable()
export class AdminReportsService {
  constructor(private prisma: PrismaService) {}

  private dateRange(query: AdminReportsQueryDto): Prisma.OrderWhereInput {
    const where: Prisma.OrderWhereInput = {
      status: { not: OrderStatus.CANCELLED },
    };
    if (query.fromDate || query.toDate) {
      where.placedAt = {};
      if (query.fromDate) where.placedAt.gte = new Date(query.fromDate);
      if (query.toDate) {
        const end = new Date(query.toDate);
        end.setHours(23, 59, 59, 999);
        where.placedAt.lte = end;
      }
    }
    return where;
  }

  async ordersReport(query: AdminReportsQueryDto) {
    const where = this.dateRange(query);
    const [orders, revenue] = await Promise.all([
      this.prisma.order.count({ where }),
      this.prisma.order.aggregate({ where, _sum: { totalAmount: true } }),
    ]);
    return {
      totalOrders: orders,
      totalRevenue: Number(revenue._sum.totalAmount || 0),
    };
  }

  async revenueReport(query: AdminReportsQueryDto) {
    const where = this.dateRange(query);
    const orders = await this.prisma.order.findMany({
      where,
      select: {
        placedAt: true,
        totalAmount: true,
        paymentMethod: true,
      },
      orderBy: { placedAt: 'asc' },
    });

    const byDay: Record<string, { revenue: number; orders: number }> = {};
    for (const o of orders) {
      const day = o.placedAt.toISOString().split('T')[0];
      if (!byDay[day]) byDay[day] = { revenue: 0, orders: 0 };
      byDay[day].revenue += Number(o.totalAmount);
      byDay[day].orders += 1;
    }

    return {
      summary: {
        totalRevenue: orders.reduce((s, o) => s + Number(o.totalAmount), 0),
        totalOrders: orders.length,
      },
      byDay: Object.entries(byDay).map(([date, v]) => ({ date, ...v })),
    };
  }

  async topProductsReport(query: AdminReportsQueryDto, limit = 10) {
    const where = this.dateRange(query);
    const orderIds = await this.prisma.order.findMany({
      where,
      select: { id: true },
    });

    const items = await this.prisma.orderItem.groupBy({
      by: ['productId', 'productName'],
      where: { orderId: { in: orderIds.map((o) => o.id) } },
      _sum: { quantity: true, totalPrice: true },
      orderBy: { _sum: { quantity: 'desc' } },
      take: limit,
    });

    return items.map((i) => ({
      productId: i.productId,
      productName: i.productName,
      quantitySold: i._sum.quantity,
      revenue: Number(i._sum.totalPrice || 0),
    }));
  }

  async exportReport(type: string, query: AdminReportsQueryDto): Promise<string> {
    const where = this.dateRange(query);

    switch (type) {
      case 'orders': {
        const orders = await this.prisma.order.findMany({
          where,
          include: {
            user: { select: { name: true, phone: true } },
          },
          orderBy: { placedAt: 'desc' },
        });
        return toCsv(
          orders.map((o) => ({
            orderNumber: o.orderNumber,
            status: o.status,
            customer: o.user.name,
            phone: o.user.phone,
            total: Number(o.totalAmount),
            placedAt: o.placedAt.toISOString(),
          })),
        );
      }
      case 'revenue': {
        const report = await this.revenueReport(query);
        return toCsv(report.byDay as Record<string, unknown>[]);
      }
      case 'products': {
        const products = await this.topProductsReport(query, 100);
        return toCsv(products as unknown as Record<string, unknown>[]);
      }
      default:
        return '';
    }
  }
}
