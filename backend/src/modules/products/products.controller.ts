import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { ProductsService } from './products.service';
import {
  CreateProductDto,
  ProductFilterDto,
  UpdateProductDto,
} from './dto/product.dto';
import { PaginationDto } from '../../common/dto/pagination.dto';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';

@ApiTags('Products')
@Controller('products')
export class ProductsController {
  constructor(private productsService: ProductsService) {}

  @Public()
  @Get()
  findAll(@Query() pagination: PaginationDto, @Query() filters: ProductFilterDto) {
    return this.productsService.findAll(pagination, filters);
  }

  @Public()
  @Get('featured')
  getFeatured(@Query() pagination: PaginationDto) {
    return this.productsService.findAll(pagination, { isFeatured: true });
  }

  @Public()
  @Get('best-sellers')
  getBestSellers(@Query() pagination: PaginationDto) {
    return this.productsService.findAll(pagination, { isBestSeller: true });
  }

  @Public()
  @Get('trending')
  getTrending(@Query() pagination: PaginationDto) {
    return this.productsService.findAll(pagination, { isTrending: true });
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @Get('admin/all')
  adminList(@Query() pagination: PaginationDto, @Query() filters: ProductFilterDto) {
    return this.productsService.findAllAdmin(pagination, filters);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @Post('admin')
  create(@Body() dto: CreateProductDto) {
    return this.productsService.create(dto);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @Patch('admin/:id')
  update(@Param('id') id: string, @Body() dto: UpdateProductDto) {
    return this.productsService.update(id, dto);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @Delete('admin/:id')
  remove(@Param('id') id: string) {
    return this.productsService.remove(id);
  }

  @Public()
  @Get(':idOrSlug')
  findOne(@Param('idOrSlug') idOrSlug: string) {
    return this.productsService.findOne(idOrSlug);
  }
}
