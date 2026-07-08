import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { generateSlug } from '../../common/utils/slug.util';
import {
  CreateCategoryDto,
  ReorderCategoriesDto,
  UpdateCategoryDto,
} from './dto/category.dto';
import { buildCategoryAliasIndex } from './category-master.config';

@Injectable()
export class CategoriesService {
  constructor(private prisma: PrismaService) {}

  private readonly childInclude = {
    children: {
      where: { isActive: true, deletedAt: null },
      orderBy: { sortOrder: 'asc' as const },
      include: { _count: { select: { products: true } } },
    },
    _count: { select: { products: true } },
  } satisfies Prisma.CategoryInclude;

  /** Flat list of top-level categories with their (one level of) children. */
  async findAll(activeOnly = true) {
    return this.prisma.category.findMany({
      where: {
        deletedAt: null,
        ...(activeOnly && { isActive: true }),
        parentId: null,
      },
      orderBy: { sortOrder: 'asc' },
      include: this.childInclude,
    });
  }

  /** Nested tree — same shape as findAll but named for clarity/versioning. */
  async tree(activeOnly = true) {
    return this.findAll(activeOnly);
  }

  async findOne(idOrSlug: string) {
    const category = await this.prisma.category.findFirst({
      where: {
        OR: [{ id: idOrSlug }, { slug: idOrSlug }],
        deletedAt: null,
      },
      include: {
        parent: { select: { id: true, name: true, slug: true } },
        children: {
          where: { deletedAt: null },
          orderBy: { sortOrder: 'asc' },
          include: { _count: { select: { products: true } } },
        },
        _count: { select: { products: true } },
      },
    });
    if (!category) throw new NotFoundException('Category not found');
    return category;
  }

  /** Subcategories of a category (accepts id or slug). */
  async subcategories(idOrSlug: string, activeOnly = true) {
    const parent = await this.findOne(idOrSlug);
    return this.prisma.category.findMany({
      where: {
        parentId: parent.id,
        deletedAt: null,
        ...(activeOnly && { isActive: true }),
      },
      orderBy: { sortOrder: 'asc' },
      include: { _count: { select: { products: true } } },
    });
  }

  /**
   * Alias-aware search. Matches on name, slug and the aliases[] array so that
   * "paneer", "atta" or "tomato sauce" resolve to the right category tree node.
   */
  async search(query: string) {
    const q = (query ?? '').trim();
    if (!q) return [];
    const norm = q.toLowerCase();

    // Resolve via the centralized alias index first (fast + deterministic).
    const index = buildCategoryAliasIndex();
    const resolvedSlugs = new Set<string>();
    const resolved = index.get(norm);
    if (resolved) {
      resolvedSlugs.add(resolved.subcategorySlug ?? resolved.categorySlug);
    }
    for (const [alias, value] of index.entries()) {
      if (alias.includes(norm) || norm.includes(alias)) {
        resolvedSlugs.add(value.subcategorySlug ?? value.categorySlug);
      }
    }

    const matches = await this.prisma.category.findMany({
      where: {
        deletedAt: null,
        isActive: true,
        OR: [
          { name: { contains: q, mode: 'insensitive' } },
          { slug: { in: Array.from(resolvedSlugs) } },
          { aliases: { has: norm } },
        ],
      },
      orderBy: [{ parentId: 'asc' }, { sortOrder: 'asc' }],
      include: {
        parent: { select: { id: true, name: true, slug: true } },
        _count: { select: { products: true } },
      },
      take: 25,
    });

    return matches;
  }

  async create(dto: CreateCategoryDto) {
    return this.prisma.category.create({
      data: {
        name: dto.name,
        slug: await this.uniqueSlug(dto.name),
        description: dto.description,
        icon: dto.icon,
        color: dto.color,
        imageUrl: dto.imageUrl,
        parentId: dto.parentId,
        aliases: dto.aliases ?? [],
        sortOrder: dto.sortOrder ?? (await this.nextSortOrder(dto.parentId)),
        isFeatured: dto.isFeatured ?? false,
      },
    });
  }

  async update(id: string, dto: UpdateCategoryDto) {
    await this.findOne(id);
    return this.prisma.category.update({
      where: { id },
      data: {
        name: dto.name,
        description: dto.description,
        icon: dto.icon,
        color: dto.color,
        imageUrl: dto.imageUrl,
        parentId: dto.parentId,
        aliases: dto.aliases,
        sortOrder: dto.sortOrder,
        isFeatured: dto.isFeatured,
        isActive: dto.isActive,
      },
    });
  }

  /** Drag & drop reordering. */
  async reorder(dto: ReorderCategoriesDto) {
    await this.prisma.$transaction(
      dto.items.map((item) =>
        this.prisma.category.update({
          where: { id: item.id },
          data: { sortOrder: item.sortOrder },
        }),
      ),
    );
    return { updated: dto.items.length };
  }

  async remove(id: string) {
    await this.findOne(id);
    return this.prisma.category.update({
      where: { id },
      data: { deletedAt: new Date(), isActive: false },
    });
  }

  private async uniqueSlug(name: string): Promise<string> {
    const base = generateSlug(name);
    let slug = base;
    let n = 1;
    while (await this.prisma.category.findUnique({ where: { slug } })) {
      slug = `${base}-${n++}`;
    }
    return slug;
  }

  private async nextSortOrder(parentId?: string): Promise<number> {
    const last = await this.prisma.category.findFirst({
      where: { parentId: parentId ?? null },
      orderBy: { sortOrder: 'desc' },
      select: { sortOrder: true },
    });
    return (last?.sortOrder ?? 0) + 1;
  }
}
