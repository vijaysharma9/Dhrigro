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

  /**
   * Category analytics: products per category/subcategory, low-stock counts,
   * inventory value per category and top-selling categories.
   */
  async categoriesReport(query: AdminReportsQueryDto) {
    const LOW_STOCK_THRESHOLD = 10;

    const [categories, products] = await Promise.all([
      this.prisma.category.findMany({
        where: { parentId: null, deletedAt: null },
        orderBy: { sortOrder: 'asc' },
        include: {
          children: {
            where: { deletedAt: null },
            orderBy: { sortOrder: 'asc' },
            select: { id: true, name: true, slug: true },
          },
        },
      }),
      this.prisma.product.findMany({
        where: { deletedAt: null, isActive: true },
        select: {
          categoryId: true,
          subcategoryId: true,
          stock: true,
          basePrice: true,
        },
      }),
    ]);

    const subAgg = new Map<string, number>();
    const catAgg = new Map<
      string,
      { productCount: number; lowStock: number; inventoryValue: number }
    >();
    for (const p of products) {
      const bucket = catAgg.get(p.categoryId) ?? {
        productCount: 0,
        lowStock: 0,
        inventoryValue: 0,
      };
      bucket.productCount += 1;
      if (p.stock <= LOW_STOCK_THRESHOLD) bucket.lowStock += 1;
      bucket.inventoryValue += p.stock * Number(p.basePrice);
      catAgg.set(p.categoryId, bucket);
      if (p.subcategoryId) {
        subAgg.set(p.subcategoryId, (subAgg.get(p.subcategoryId) ?? 0) + 1);
      }
    }

    // Top selling categories (by quantity in the selected window).
    const where = this.dateRange(query);
    const orderIds = await this.prisma.order.findMany({
      where,
      select: { id: true },
    });
    const items = await this.prisma.orderItem.groupBy({
      by: ['productId'],
      where: { orderId: { in: orderIds.map((o) => o.id) } },
      _sum: { quantity: true, totalPrice: true },
    });
    const productCategory = await this.prisma.product.findMany({
      where: { id: { in: items.map((i) => i.productId) } },
      select: { id: true, categoryId: true },
    });
    const prodToCat = new Map(productCategory.map((p) => [p.id, p.categoryId]));
    const sellingByCat = new Map<string, { quantity: number; revenue: number }>();
    for (const i of items) {
      const catId = prodToCat.get(i.productId);
      if (!catId) continue;
      const b = sellingByCat.get(catId) ?? { quantity: 0, revenue: 0 };
      b.quantity += i._sum.quantity ?? 0;
      b.revenue += Number(i._sum.totalPrice ?? 0);
      sellingByCat.set(catId, b);
    }

    const byCategory = categories.map((c) => {
      const agg = catAgg.get(c.id) ?? {
        productCount: 0,
        lowStock: 0,
        inventoryValue: 0,
      };
      return {
        id: c.id,
        name: c.name,
        slug: c.slug,
        icon: c.icon,
        color: c.color,
        productCount: agg.productCount,
        lowStock: agg.lowStock,
        inventoryValue: Math.round(agg.inventoryValue),
        subcategories: c.children.map((s) => ({
          id: s.id,
          name: s.name,
          slug: s.slug,
          productCount: subAgg.get(s.id) ?? 0,
        })),
      };
    });

    const topSelling = categories
      .map((c) => ({
        id: c.id,
        name: c.name,
        color: c.color,
        quantitySold: sellingByCat.get(c.id)?.quantity ?? 0,
        revenue: Math.round(sellingByCat.get(c.id)?.revenue ?? 0),
      }))
      .filter((c) => c.quantitySold > 0)
      .sort((a, b) => b.quantitySold - a.quantitySold)
      .slice(0, 10);

    return {
      totals: {
        categories: categories.length,
        products: products.length,
        lowStock: byCategory.reduce((s, c) => s + c.lowStock, 0),
        inventoryValue: byCategory.reduce((s, c) => s + c.inventoryValue, 0),
      },
      byCategory,
      topSelling,
    };
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
