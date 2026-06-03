import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { generateSlug } from '../../common/utils/slug.util';

@Injectable()
export class CategoriesService {
  constructor(private prisma: PrismaService) {}

  async findAll(activeOnly = true) {
    return this.prisma.category.findMany({
      where: {
        deletedAt: null,
        ...(activeOnly && { isActive: true }),
        parentId: null,
      },
      orderBy: { sortOrder: 'asc' },
      include: {
        children: {
          where: { isActive: true, deletedAt: null },
          orderBy: { sortOrder: 'asc' },
        },
        _count: { select: { products: true } },
      },
    });
  }

  async findOne(idOrSlug: string) {
    const category = await this.prisma.category.findFirst({
      where: {
        OR: [{ id: idOrSlug }, { slug: idOrSlug }],
        deletedAt: null,
      },
      include: { children: true },
    });
    if (!category) throw new NotFoundException('Category not found');
    return category;
  }

  async create(data: {
    name: string;
    description?: string;
    imageUrl?: string;
    parentId?: string;
    sortOrder?: number;
  }) {
    return this.prisma.category.create({
      data: {
        name: data.name,
        slug: `${generateSlug(data.name)}-${Date.now()}`,
        description: data.description,
        imageUrl: data.imageUrl,
        parentId: data.parentId,
        sortOrder: data.sortOrder ?? 0,
      },
    });
  }

  async update(
    id: string,
    data: Partial<{
      name: string;
      description: string;
      imageUrl: string;
      isActive: boolean;
      sortOrder: number;
    }>,
  ) {
    await this.findOne(id);
    return this.prisma.category.update({ where: { id }, data });
  }

  async remove(id: string) {
    await this.findOne(id);
    return this.prisma.category.update({
      where: { id },
      data: { deletedAt: new Date(), isActive: false },
    });
  }
}
