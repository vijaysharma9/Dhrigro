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
  AdminProductsQueryDto,
  CreateProductDto,
  ProductFilterDto,
  ProductsQueryDto,
  UpdateProductDto,
} from './dto/product.dto';
import { ImportProductsDto } from './dto/product-import.dto';
import { PaginationDto } from '../../common/dto/pagination.dto';
import { toCsv } from '../../common/utils/csv.util';
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
  findAll(@Query() query: ProductsQueryDto) {
    const { page, limit, search, sortBy, sortOrder, ...filterFields } = query;
    return this.productsService.findAll(
      { page, limit, search, sortBy, sortOrder },
      { ...filterFields, search } as ProductFilterDto,
    );
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
  @Roles(UserRole.SUPER_ADMIN, UserRole.INVENTORY_MANAGER)
  @Get('admin/all')
  adminList(@Query() query: AdminProductsQueryDto) {
    const { page, limit, search, sortBy, sortOrder, ...filterFields } = query;
    return this.productsService.findAllAdmin(
      { page, limit, search, sortBy, sortOrder },
      { ...filterFields, search } as ProductFilterDto,
    );
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

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SUPER_ADMIN, UserRole.INVENTORY_MANAGER)
  @Get('admin/duplicates')
  findDuplicates() {
    return this.productsService.findDuplicates();
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @Post('admin/duplicates/resolve')
  resolveDuplicates(
    @Body() body: { keepId: string; removeIds: string[] },
  ) {
    return this.productsService.resolveDuplicates(body.keepId, body.removeIds);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @Post('admin/import')
  importProducts(@Body() dto: ImportProductsDto) {
    return this.productsService.importProducts(dto.rows, dto.matchBy);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SUPER_ADMIN, UserRole.INVENTORY_MANAGER)
  @Get('admin/import-template')
  importTemplate() {
    const csv = toCsv([
      {
        name: 'Sample Product',
        category: 'Fruits & Vegetables',
        basePrice: 99,
        discountPrice: 89,
        stock: 50,
        unit: 'kg',
        sku: 'SKU-001',
        description: 'Optional description',
        imageUrl: 'https://example.com/image.jpg',
        isFeatured: false,
        isActive: true,
      },
    ]);
    return { filename: 'product-import-template.csv', csv };
  }

  @Public()
  @Get(':idOrSlug')
  findOne(@Param('idOrSlug') idOrSlug: string) {
    return this.productsService.findOne(idOrSlug);
  }
}
