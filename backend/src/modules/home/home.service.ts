import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import { CacheService } from '../../redis/cache.service';

@Injectable()
export class HomeService {
  constructor(
    private prisma: PrismaService,
    private cache: CacheService,
    private configService: ConfigService,
  ) {}

  async getHomeData() {
    const ttl = this.configService.get<number>('cache.homeTtl') || 120;
    return this.cache.wrap('home:feed', ttl, async () => {
      const [banners, categories, featured, bestSellers, trending] =
        await Promise.all([
          this.prisma.banner.findMany({
            where: { isActive: true },
            orderBy: { sortOrder: 'asc' },
            take: 5,
          }),
          this.prisma.category.findMany({
            where: { isActive: true, deletedAt: null, parentId: null },
            orderBy: { sortOrder: 'asc' },
            take: 12,
          }),
          this.prisma.product.findMany({
            where: { isActive: true, isFeatured: true, deletedAt: null },
            take: 10,
            include: { variants: true, productImages: { take: 1 } },
          }),
          this.prisma.product.findMany({
            where: { isActive: true, isBestSeller: true, deletedAt: null },
            take: 10,
            include: { variants: true, productImages: { take: 1 } },
          }),
          this.prisma.product.findMany({
            where: { isActive: true, isTrending: true, deletedAt: null },
            take: 10,
            include: { variants: true, productImages: { take: 1 } },
          }),
        ]);

      const settings = await this.prisma.deliverySettings.findFirst();

      return {
        banners,
        categories,
        featuredProducts: featured,
        bestSellers,
        trendingProducts: trending,
        deliveryInfo: {
          message: 'Next morning delivery by 9 AM',
          sameDayEnabled: settings?.sameDayEnabled ?? true,
        },
      };
    });
  }
}
