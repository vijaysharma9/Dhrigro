import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class BannersService {
  constructor(private prisma: PrismaService) {}

  async findActive() {
    const now = new Date();
    return this.prisma.banner.findMany({
      where: {
        isActive: true,
        OR: [{ startsAt: null }, { startsAt: { lte: now } }],
        AND: [{ OR: [{ expiresAt: null }, { expiresAt: { gte: now } }] }],
      },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async findAll() {
    return this.prisma.banner.findMany({ orderBy: { sortOrder: 'asc' } });
  }

  async create(data: {
    title: string;
    subtitle?: string;
    imageUrl: string;
    thumbnailUrl?: string;
    imagePublicId?: string;
    linkUrl?: string;
    sortOrder?: number;
  }) {
    return this.prisma.banner.create({ data });
  }

  async update(id: string, data: Record<string, unknown>) {
    return this.prisma.banner.update({ where: { id }, data });
  }

  async remove(id: string) {
    return this.prisma.banner.delete({ where: { id } });
  }
}
