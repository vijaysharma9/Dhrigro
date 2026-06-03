import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../prisma/prisma.service';
import {
  paginate,
  paginatedResponse,
} from '../../../common/dto/pagination.dto';
import { AdminInventoryQueryDto } from '../dto/admin-query.dto';

@Injectable()
export class AdminInventoryService {
  constructor(private prisma: PrismaService) {}

  async listInventory(query: AdminInventoryQueryDto) {
    const { page = 1, limit = 20 } = query;
    const { take, skip } = paginate(page, limit);
    const threshold = query.lowStockThreshold ?? 10;

    const where: Prisma.ProductWhereInput = {
      deletedAt: null,
      ...(query.search && {
        name: { contains: query.search, mode: 'insensitive' },
      }),
      ...(query.lowStock && { stock: { lte: threshold } }),
    };

    const [data, total, lowStockCount, outOfStockCount] = await Promise.all([
      this.prisma.product.findMany({
        where,
        skip,
        take,
        orderBy: { stock: 'asc' },
        select: {
          id: true,
          name: true,
          sku: true,
          stock: true,
          isActive: true,
          basePrice: true,
          category: { select: { name: true } },
        },
      }),
      this.prisma.product.count({ where }),
      this.prisma.product.count({
        where: { deletedAt: null, stock: { lte: threshold, gt: 0 } },
      }),
      this.prisma.product.count({
        where: { deletedAt: null, stock: 0 },
      }),
    ]);

    const paginated = paginatedResponse(data, total, page, limit);
    return {
      ...paginated,
      meta: {
        ...paginated.meta,
        lowStockCount,
        outOfStockCount,
      },
    };
  }

  async updateStock(productId: string, stock: number, isActive?: boolean) {
    const product = await this.prisma.product.findFirst({
      where: { id: productId, deletedAt: null },
    });
    if (!product) throw new NotFoundException('Product not found');

    return this.prisma.product.update({
      where: { id: productId },
      data: {
        stock,
        ...(isActive !== undefined && { isActive }),
      },
    });
  }

  async bulkUpdateStock(
    updates: { productId: string; stock: number; isActive?: boolean }[],
  ) {
    const results = await this.prisma.$transaction(
      updates.map((u) =>
        this.prisma.product.update({
          where: { id: u.productId },
          data: {
            stock: u.stock,
            ...(u.isActive !== undefined && { isActive: u.isActive }),
          },
        }),
      ),
    );
    return { updated: results.length, products: results };
  }
}
