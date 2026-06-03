import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { PrismaService } from '../../prisma/prisma.service';
import { Public } from '../../common/decorators/public.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { HomeService } from './home.service';

@ApiTags('Home')
@Controller('home')
export class HomeController {
  constructor(
    private homeService: HomeService,
    private prisma: PrismaService,
  ) {}

  @Public()
  @Get()
  getHomeData() {
    return this.homeService.getHomeData();
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('recent-orders')
  async getRecentOrders(@CurrentUser('id') userId: string) {
    const orders = await this.prisma.order.findMany({
      where: { userId },
      orderBy: { placedAt: 'desc' },
      take: 5,
      include: { items: true },
    });
    return { recentOrders: orders };
  }
}
