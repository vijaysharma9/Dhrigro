import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import {
  paginate,
  paginatedResponse,
  PaginationDto,
} from '../../common/dto/pagination.dto';
import { generateSlug } from '../../common/utils/slug.util';
import {
  CreateProductDto,
  ProductFilterDto,
  UpdateProductDto,
} from './dto/product.dto';
import { ImportProductRowDto } from './dto/product-import.dto';
import { buildCategoryAliasIndex } from '../categories/category-master.config';

@Injectable()
export class ProductsService {
  constructor(private prisma: PrismaService) {}

  private serializeProduct(product: Record<string, unknown>) {
    const productImages = product.productImages as
      | Array<Record<string, unknown>>
      | undefined;
    const imageUrlsFromRelation = productImages?.length
      ? productImages
          .sort(
            (a, b) =>
              ((b.isFeatured as boolean) ? 1 : 0) -
                ((a.isFeatured as boolean) ? 1 : 0) ||
              ((a.sortOrder as number) ?? 0) - ((b.sortOrder as number) ?? 0),
          )
          .map((img) => img.imageUrl as string)
      : null;

    return {
      ...product,
      basePrice: Number(product.basePrice),
      discountPrice: product.discountPrice
        ? Number(product.discountPrice)
        : null,
      images: imageUrlsFromRelation?.length
        ? imageUrlsFromRelation
        : (product.images as string[]) ?? [],
      productImages: productImages ?? [],
      variants: Array.isArray(product.variants)
        ? product.variants.map((v: Record<string, unknown>) => ({
            ...v,
            price: Number(v.price),
            discountPrice: v.discountPrice ? Number(v.discountPrice) : null,
          }))
        : [],
    };
  }

  private productInclude = {
    category: true,
    subcategory: true,
    variants: true,
    productImages: {
      orderBy: [{ isFeatured: 'desc' as const }, { sortOrder: 'asc' as const }],
    },
  };

  async create(dto: CreateProductDto) {
    const slug = generateSlug(dto.name);
    const product = await this.prisma.product.create({
      data: {
        name: dto.name,
        slug: `${slug}-${Date.now()}`,
        description: dto.description,
        categoryId: dto.categoryId,
        subcategoryId: dto.subcategoryId ?? null,
        basePrice: dto.basePrice,
        discountPrice: dto.discountPrice,
        stock: dto.stock ?? 0,
        unit: dto.unit ?? 'piece',
        weight: dto.weight,
        images: dto.images ?? [],
        isFeatured: dto.isFeatured ?? false,
        isBestSeller: dto.isBestSeller ?? false,
        isTrending: dto.isTrending ?? false,
        tags: dto.tags ?? [],
        variants: dto.variants?.length
          ? {
              create: dto.variants.map((v) => ({
                label: v.label,
                price: v.price,
                discountPrice: v.discountPrice,
                stock: v.stock ?? 0,
                isDefault: v.isDefault ?? false,
              })),
            }
          : undefined,
      },
      include: this.productInclude,
    });
    return this.serializeProduct(product as Record<string, unknown>);
  }

  async findAll(pagination: PaginationDto, filters: ProductFilterDto) {
    const { page = 1, limit = 20 } = pagination;
    const { take, skip } = paginate(page, limit);

    const where: Prisma.ProductWhereInput = {
      deletedAt: null,
      isActive: true,
      ...(filters.categoryId && { categoryId: filters.categoryId }),
      ...(filters.subcategoryId && { subcategoryId: filters.subcategoryId }),
      ...(filters.isFeatured !== undefined && { isFeatured: filters.isFeatured }),
      ...(filters.isBestSeller !== undefined && {
        isBestSeller: filters.isBestSeller,
      }),
      ...(filters.isTrending !== undefined && { isTrending: filters.isTrending }),
      ...(filters.search && {
        OR: [
          { name: { contains: filters.search, mode: 'insensitive' } },
          { description: { contains: filters.search, mode: 'insensitive' } },
          { tags: { has: filters.search } },
        ],
      }),
      ...((filters.minPrice || filters.maxPrice) && {
        basePrice: {
          ...(filters.minPrice && { gte: filters.minPrice }),
          ...(filters.maxPrice && { lte: filters.maxPrice }),
        },
      }),
    };

    const orderBy: Prisma.ProductOrderByWithRelationInput = {};
    const sort = filters.sortBy || pagination.sortBy;
    if (sort === 'price' || sort === 'price_asc') {
      orderBy.basePrice = 'asc';
    } else if (sort === 'price_desc') {
      orderBy.basePrice = 'desc';
    } else if (sort === 'name') {
      orderBy.name = filters.sortOrder || pagination.sortOrder || 'asc';
    } else {
      orderBy.createdAt = 'desc';
    }

    const [data, total] = await Promise.all([
      this.prisma.product.findMany({
        where,
        skip,
        take,
        orderBy,
        include: this.productInclude,
      }),
      this.prisma.product.count({ where }),
    ]);

    return paginatedResponse(
      data.map((p) => this.serializeProduct(p as Record<string, unknown>)),
      total,
      page,
      limit,
    );
  }

  async findAllAdmin(pagination: PaginationDto, filters: ProductFilterDto) {
    const { page = 1, limit = 20 } = pagination;
    const { take, skip } = paginate(page, limit);

    const where: Prisma.ProductWhereInput = {
      deletedAt: null,
      ...(filters.categoryId && { categoryId: filters.categoryId }),
      ...(filters.subcategoryId && { subcategoryId: filters.subcategoryId }),
      ...(filters.isFeatured !== undefined && { isFeatured: filters.isFeatured }),
      ...(filters.isBestSeller !== undefined && {
        isBestSeller: filters.isBestSeller,
      }),
      ...(filters.isTrending !== undefined && { isTrending: filters.isTrending }),
      ...(filters.search && {
        OR: [
          { name: { contains: filters.search, mode: 'insensitive' } },
          { description: { contains: filters.search, mode: 'insensitive' } },
          { tags: { has: filters.search } },
        ],
      }),
      ...((filters.minPrice || filters.maxPrice) && {
        basePrice: {
          ...(filters.minPrice && { gte: filters.minPrice }),
          ...(filters.maxPrice && { lte: filters.maxPrice }),
        },
      }),
    };

    const [data, total] = await Promise.all([
      this.prisma.product.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: this.productInclude,
      }),
      this.prisma.product.count({ where }),
    ]);

    return paginatedResponse(
      data.map((p) => this.serializeProduct(p as Record<string, unknown>)),
      total,
      page,
      limit,
    );
  }

  async findOne(idOrSlug: string) {
    const product = await this.prisma.product.findFirst({
      where: {
        OR: [{ id: idOrSlug }, { slug: idOrSlug }],
        deletedAt: null,
      },
      include: {
        ...this.productInclude,
        reviews: {
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: { user: { select: { name: true, avatarUrl: true } } },
        },
      },
    });

    if (!product) {
      throw new NotFoundException('Product not found');
    }

    const related = await this.prisma.product.findMany({
      where: {
        categoryId: product.categoryId,
        id: { not: product.id },
        isActive: true,
        deletedAt: null,
      },
      take: 8,
      include: { variants: true },
    });

    return {
      ...this.serializeProduct(product as Record<string, unknown>),
      relatedProducts: related.map((p) =>
        this.serializeProduct(p as Record<string, unknown>),
      ),
    };
  }

  async update(id: string, dto: UpdateProductDto) {
    await this.findOne(id);
    const product = await this.prisma.product.update({
      where: { id },
      data: {
        ...dto,
        ...(dto.name && { slug: generateSlug(dto.name) }),
      },
      include: this.productInclude,
    });
    return this.serializeProduct(product as Record<string, unknown>);
  }

  async remove(id: string) {
    await this.findOne(id);
    await this.prisma.product.update({
      where: { id },
      data: { deletedAt: new Date(), isActive: false },
    });
    return { message: 'Product deleted' };
  }

  async importProducts(
    rows: ImportProductRowDto[],
    matchBy: 'sku_or_name' | 'sku' | 'name' = 'sku_or_name',
  ) {
    const categories = await this.prisma.category.findMany({
      where: { deletedAt: null },
    });
    const categoryById = new Map(categories.map((c) => [c.id, c]));
    const categoryByName = new Map(
      categories.map((c) => [c.name.trim().toLowerCase(), c]),
    );
    const categoryBySlug = new Map(categories.map((c) => [c.slug, c]));
    const aliasIndex = buildCategoryAliasIndex();

    let created = 0;
    let updated = 0;
    let failed = 0;
    const errors: Array<{ row: number; name?: string; message: string }> = [];

    // Track rows created/updated in this batch so duplicate lines in the same
    // file update instead of creating extra products.
    const batchBySku = new Map<string, string>();
    const batchByNameCategory = new Map<string, string>();

    for (let index = 0; index < rows.length; index++) {
      const row = rows[index];
      const rowNumber = index + 2;

      try {
        const resolved = this.resolveImportCategory(
          row,
          categoryById,
          categoryByName,
          categoryBySlug,
          aliasIndex,
        );
        if (!resolved) {
          const provided =
            row.subcategory?.trim() ||
            row.category?.trim() ||
            row.alias?.trim() ||
            row.categoryId?.trim();
          throw new Error(
            provided
              ? `Unknown category "${provided}" — no matching category/subcategory/alias found`
              : 'Category is required — use categoryId, category, subcategory or alias',
          );
        }

        const images = row.imageUrl?.trim() ? [row.imageUrl.trim()] : [];
        const normalizedSku = this.normalizeSku(row.sku);
        const normalizedName = row.name.trim();
        const nameCategoryKey = `${resolved.categoryId}::${normalizedName.toLowerCase()}`;

        const productData = {
          name: normalizedName,
          description: row.description?.trim() || undefined,
          categoryId: resolved.categoryId,
          subcategoryId: resolved.subcategoryId ?? null,
          basePrice: row.basePrice,
          discountPrice: row.discountPrice ?? null,
          stock: row.stock ?? 0,
          unit: row.unit?.trim() || 'piece',
          sku: normalizedSku,
          images,
          isFeatured: row.isFeatured ?? false,
          isActive: row.isActive ?? true,
        };

        const existingId = await this.findImportMatch(
          productData,
          matchBy,
          batchBySku,
          batchByNameCategory,
        );

        if (existingId) {
          await this.prisma.product.update({
            where: { id: existingId },
            data: productData,
          });
          if (normalizedSku) batchBySku.set(normalizedSku, existingId);
          batchByNameCategory.set(nameCategoryKey, existingId);
          updated++;
          continue;
        }

        const slug = `${generateSlug(normalizedName)}-${Date.now()}-${index}`;
        const createdProduct = await this.prisma.product.create({
          data: {
            ...productData,
            slug,
          },
        });
        if (normalizedSku) batchBySku.set(normalizedSku, createdProduct.id);
        batchByNameCategory.set(nameCategoryKey, createdProduct.id);
        created++;
      } catch (error) {
        failed++;
        errors.push({
          row: rowNumber,
          name: row.name,
          message:
            error instanceof Error ? error.message : 'Failed to import row',
        });
      }
    }

    return {
      created,
      updated,
      failed,
      total: rows.length,
      matchBy,
      errors,
    };
  }

  /** Groups active products that share the same name (case-insensitive). */
  async findDuplicates() {
    const products = await this.prisma.product.findMany({
      where: { deletedAt: null },
      orderBy: { name: 'asc' },
      select: {
        id: true,
        name: true,
        sku: true,
        basePrice: true,
        discountPrice: true,
        stock: true,
        isActive: true,
        updatedAt: true,
        category: { select: { id: true, name: true } },
      },
    });

    const groups = new Map<string, typeof products>();
    for (const p of products) {
      const key = p.name.trim().toLowerCase();
      const list = groups.get(key) ?? [];
      list.push(p);
      groups.set(key, list);
    }

    const duplicateGroups = Array.from(groups.entries())
      .filter(([, items]) => items.length > 1)
      .map(([key, items]) => ({
        key,
        name: items[0].name,
        count: items.length,
        products: items.map((p) => ({
          ...p,
          basePrice: Number(p.basePrice),
          discountPrice: p.discountPrice ? Number(p.discountPrice) : null,
        })),
      }))
      .sort((a, b) => b.count - a.count);

    return {
      totalDuplicateProducts: duplicateGroups.reduce(
        (sum, g) => sum + g.count - 1,
        0,
      ),
      groups: duplicateGroups,
    };
  }

  /** Soft-delete duplicate products, keeping the chosen canonical row. */
  async resolveDuplicates(keepId: string, removeIds: string[]) {
    const uniqueRemove = removeIds.filter((id) => id !== keepId);
    if (!keepId || uniqueRemove.length === 0) {
      return { removed: 0 };
    }

    const keep = await this.prisma.product.findFirst({
      where: { id: keepId, deletedAt: null },
    });
    if (!keep) throw new NotFoundException('Product to keep not found');

    const result = await this.prisma.product.updateMany({
      where: { id: { in: uniqueRemove }, deletedAt: null },
      data: { deletedAt: new Date(), isActive: false },
    });

    return { removed: result.count, keptId: keepId };
  }

  private normalizeSku(sku?: string): string | undefined {
    const value = sku?.trim();
    return value ? value.toUpperCase() : undefined;
  }

  private async findImportMatch(
    productData: {
      name: string;
      categoryId: string;
      sku?: string;
    },
    matchBy: 'sku_or_name' | 'sku' | 'name',
    batchBySku: Map<string, string>,
    batchByNameCategory: Map<string, string>,
  ): Promise<string | null> {
    const nameCategoryKey = `${productData.categoryId}::${productData.name.toLowerCase()}`;

    const trySku = matchBy === 'sku' || matchBy === 'sku_or_name';
    const tryName = matchBy === 'name' || matchBy === 'sku_or_name';

    if (trySku && productData.sku) {
      const batchHit = batchBySku.get(productData.sku);
      if (batchHit) return batchHit;

      const bySku = await this.prisma.product.findFirst({
        where: {
          sku: { equals: productData.sku, mode: 'insensitive' },
          deletedAt: null,
        },
        select: { id: true },
      });
      if (bySku) return bySku.id;
    }

    if (tryName) {
      const batchHit = batchByNameCategory.get(nameCategoryKey);
      if (batchHit) return batchHit;

      const byName = await this.prisma.product.findFirst({
        where: {
          name: { equals: productData.name, mode: 'insensitive' },
          categoryId: productData.categoryId,
          deletedAt: null,
        },
        orderBy: { updatedAt: 'desc' },
        select: { id: true },
      });
      if (byName) return byName.id;
    }

    return null;
  }

  /**
   * Resolves a CSV row to a concrete { categoryId, subcategoryId } using the
   * centralized alias index. Accepts categoryId, category, subcategory or a
   * free-text alias in any combination.
   */
  private resolveImportCategory(
    row: ImportProductRowDto,
    categoryById: Map<string, { id: string; parentId: string | null }>,
    categoryByName: Map<string, { id: string; parentId: string | null }>,
    categoryBySlug: Map<string, { id: string; parentId: string | null }>,
    aliasIndex: Map<string, { categorySlug: string; subcategorySlug?: string }>,
  ): { categoryId: string; subcategoryId?: string } | null {
    const toId = (slug?: string) => categoryBySlug.get(slug ?? '')?.id;

    // Explicit categoryId wins for the parent.
    let categoryId = row.categoryId && categoryById.has(row.categoryId)
      ? row.categoryId
      : undefined;
    let subcategoryId: string | undefined;

    // Try each free-text signal against the alias index (most specific first).
    const signals = [row.subcategory, row.alias, row.category].filter(
      (s): s is string => !!s && s.trim().length > 0,
    );

    for (const signal of signals) {
      const hit = this.lookupAlias(signal, aliasIndex, categoryByName);
      if (!hit) continue;
      if (hit.subcategorySlug && !subcategoryId) {
        subcategoryId = toId(hit.subcategorySlug);
      }
      if (!categoryId) {
        categoryId = toId(hit.categorySlug);
      }
    }

    if (!categoryId) return null;
    return { categoryId, subcategoryId };
  }

  private lookupAlias(
    value: string,
    aliasIndex: Map<string, { categorySlug: string; subcategorySlug?: string }>,
    categoryByName: Map<string, { id: string; parentId: string | null }>,
  ): { categorySlug: string; subcategorySlug?: string } | undefined {
    const norm = value.trim().toLowerCase();
    if (!norm) return undefined;

    // 1. Exact alias / name / slug hit.
    const exact = aliasIndex.get(norm);
    if (exact) return exact;

    // 2. Slugified hit.
    const slugified = norm.replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
    const slugHit = aliasIndex.get(slugified);
    if (slugHit) return slugHit;

    // 3. Substring / word-overlap fallback against the alias index.
    let best: { categorySlug: string; subcategorySlug?: string } | undefined;
    let bestLen = 0;
    for (const [alias, hit] of aliasIndex.entries()) {
      if (
        (norm.includes(alias) || alias.includes(norm)) &&
        alias.length > bestLen
      ) {
        best = hit;
        bestLen = alias.length;
      }
    }
    return best;
  }
}
