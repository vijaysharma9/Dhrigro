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
    if (filters.sortBy === 'price') {
      orderBy.basePrice = filters.sortOrder || 'asc';
    } else if (filters.sortBy === 'name') {
      orderBy.name = filters.sortOrder || 'asc';
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
      ...(filters.search && {
        name: { contains: filters.search, mode: 'insensitive' },
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
}
