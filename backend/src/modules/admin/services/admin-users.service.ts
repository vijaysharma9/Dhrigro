import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
import { PrismaService } from '../../../prisma/prisma.service';
import {
  paginate,
  paginatedResponse,
} from '../../../common/dto/pagination.dto';
import { toCsv } from '../../../common/utils/csv.util';
import { AdminUsersQueryDto } from '../dto/admin-query.dto';

@Injectable()
export class AdminUsersService {
  constructor(private prisma: PrismaService) {}

  async listUsers(query: AdminUsersQueryDto) {
    const { page = 1, limit = 20 } = query;
    const { take, skip } = paginate(page, limit);

    const where: Prisma.UserWhereInput = {
      deletedAt: null,
      role: UserRole.CUSTOMER,
    };

    if (query.isActive !== undefined) where.isActive = query.isActive;

    if (query.search) {
      where.OR = [
        { name: { contains: query.search, mode: 'insensitive' } },
        { email: { contains: query.search, mode: 'insensitive' } },
        { phone: { contains: query.search } },
      ];
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          isActive: true,
          isVerified: true,
          createdAt: true,
          _count: { select: { orders: true, addresses: true } },
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    const data = await Promise.all(
      users.map(async (u) => {
        const [spend, lastOrder] = await Promise.all([
          this.prisma.order.aggregate({
            where: { userId: u.id, status: { not: 'CANCELLED' } },
            _sum: { totalAmount: true },
          }),
          this.prisma.order.findFirst({
            where: { userId: u.id },
            orderBy: { placedAt: 'desc' },
            select: { placedAt: true, paymentMethod: true },
          }),
        ]);
        return {
          ...u,
          totalSpend: Number(spend._sum.totalAmount || 0),
          lastOrderAt: lastOrder?.placedAt ?? null,
          preferredPaymentMethod: lastOrder?.paymentMethod ?? null,
        };
      }),
    );

    return paginatedResponse(data, total, page, limit);
  }

  async getUserDetail(id: string) {
    const user = await this.prisma.user.findFirst({
      where: { id, deletedAt: null },
      include: {
        addresses: true,
        orders: {
          take: 20,
          orderBy: { placedAt: 'desc' },
          include: { items: true },
        },
      },
    });
    if (!user) throw new NotFoundException('User not found');

    const totalSpend = await this.prisma.order.aggregate({
      where: { userId: id, status: { not: 'CANCELLED' } },
      _sum: { totalAmount: true },
      _count: true,
    });

    const couponsUsed = await this.prisma.order.count({
      where: { userId: id, couponId: { not: null } },
    });

    const lastOrder = user.orders[0];
    const totalOrders = totalSpend._count;
    const totalSpendNum = Number(totalSpend._sum.totalAmount || 0);
    const avgOrderValue = totalOrders > 0 ? totalSpendNum / totalOrders : 0;

    const paymentMethods = await this.prisma.order.groupBy({
      by: ['paymentMethod'],
      where: { userId: id, status: { not: 'CANCELLED' } },
      _count: true,
    });
    const preferredPayment =
      paymentMethods.sort((a, b) => b._count - a._count)[0]?.paymentMethod ?? null;

    return {
      ...user,
      stats: {
        totalOrders,
        totalSpend: totalSpendNum,
        couponsUsed,
        avgOrderValue,
        repeatPurchaseRate:
          totalOrders > 1 ? Math.min(100, ((totalOrders - 1) / totalOrders) * 100) : 0,
        lastOrderAt: lastOrder?.placedAt ?? null,
        preferredPaymentMethod: preferredPayment,
      },
    };
  }

  async setUserActive(id: string, isActive: boolean) {
    const user = await this.prisma.user.findFirst({
      where: { id, role: UserRole.CUSTOMER },
    });
    if (!user) throw new NotFoundException('Customer not found');

    return this.prisma.user.update({
      where: { id },
      data: { isActive },
      select: { id: true, name: true, isActive: true },
    });
  }

  async exportUsersCsv(query: AdminUsersQueryDto) {
    const result = await this.listUsers({ ...query, page: 1, limit: 10000 });
    const rows = (result.data as Record<string, unknown>[]).map((u) => ({
      name: u.name,
      email: u.email,
      phone: u.phone,
      isActive: u.isActive,
      orders: (u._count as Record<string, number>)?.orders,
      totalSpend: u.totalSpend,
      createdAt: u.createdAt,
    }));
    return toCsv(rows);
  }
}
