import { Injectable, NotFoundException } from '@nestjs/common';
import { OrderStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../../prisma/prisma.service';
import { OrdersService } from '../../orders/orders.service';
import {
  paginate,
  paginatedResponse,
} from '../../../common/dto/pagination.dto';
import { toCsv } from '../../../common/utils/csv.util';
import { AdminOrdersQueryDto } from '../dto/admin-query.dto';

@Injectable()
export class AdminOrdersService {
  constructor(
    private prisma: PrismaService,
    private ordersService: OrdersService,
  ) {}

  private orderInclude = {
    user: { select: { id: true, name: true, phone: true, email: true } },
    items: { include: { product: { select: { id: true, name: true, images: true } } } },
    address: true,
    deliverySlot: true,
    coupon: true,
    transactions: true,
    statusLogs: { orderBy: { createdAt: 'asc' as const } },
    assignment: {
      include: {
        partner: { select: { id: true, name: true, phone: true } },
      },
    },
  };

  async listOrders(query: AdminOrdersQueryDto) {
    const { page = 1, limit = 20 } = query;
    const { take, skip } = paginate(page, limit);

    const where: Prisma.OrderWhereInput = {};

    if (query.status) where.status = query.status;
    if (query.paymentMethod) where.paymentMethod = query.paymentMethod;

    if (query.fromDate || query.toDate) {
      where.placedAt = {};
      if (query.fromDate) where.placedAt.gte = new Date(query.fromDate);
      if (query.toDate) {
        const end = new Date(query.toDate);
        end.setHours(23, 59, 59, 999);
        where.placedAt.lte = end;
      }
    }

    if (query.search) {
      where.OR = [
        { orderNumber: { contains: query.search, mode: 'insensitive' } },
        { user: { name: { contains: query.search, mode: 'insensitive' } } },
        { user: { phone: { contains: query.search } } },
      ];
    }

    const orderBy: Prisma.OrderOrderByWithRelationInput = {};
    if (query.sortBy === 'totalAmount') {
      orderBy.totalAmount = query.sortOrder || 'desc';
    } else {
      orderBy.placedAt = query.sortOrder || 'desc';
    }

    const [data, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        skip,
        take,
        orderBy,
        include: this.orderInclude,
      }),
      this.prisma.order.count({ where }),
    ]);

    return paginatedResponse(
      data.map((o) => this.serializeOrder(o)),
      total,
      page,
      limit,
    );
  }

  async getOrder(id: string) {
    const order = await this.prisma.order.findUnique({
      where: { id },
      include: this.orderInclude,
    });
    if (!order) throw new NotFoundException('Order not found');
    return this.serializeOrder(order);
  }

  async updateStatus(
    id: string,
    status: OrderStatus,
    note?: string,
    cancelledReason?: string,
  ) {
    return this.ordersService.updateStatus(id, status, note, cancelledReason);
  }

  async assignDeliverySlot(orderId: string, deliverySlotId: string) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException('Order not found');

    const slot = await this.prisma.deliverySlot.findUnique({
      where: { id: deliverySlotId },
    });
    if (!slot) throw new NotFoundException('Delivery slot not found');

    return this.prisma.order.update({
      where: { id: orderId },
      data: { deliverySlotId },
      include: this.orderInclude,
    });
  }

  async exportOrdersCsv(query: AdminOrdersQueryDto) {
    const result = await this.listOrders({ ...query, page: 1, limit: 10000 });
    const rows = (result.data as Record<string, unknown>[]).map((o) => ({
      orderNumber: o.orderNumber,
      status: o.status,
      customer: (o.user as Record<string, unknown>)?.name,
      phone: (o.user as Record<string, unknown>)?.phone,
      paymentMethod: o.paymentMethod,
      paymentStatus: o.paymentStatus,
      totalAmount: o.totalAmount,
      placedAt: o.placedAt,
    }));
    return toCsv(rows);
  }

  private serializeOrder(order: Record<string, unknown>) {
    return {
      ...order,
      subtotal: Number(order.subtotal),
      discountAmount: Number(order.discountAmount),
      deliveryFee: Number(order.deliveryFee),
      sameDayFee: Number(order.sameDayFee),
      totalAmount: Number(order.totalAmount),
    };
  }
}
