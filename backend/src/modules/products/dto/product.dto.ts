import {
  IsArray,
  IsBoolean,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateProductVariantDto {
  @IsNotEmpty()
  label: string;

  @IsNumber()
  @Min(0)
  price: number;

  @IsOptional()
  @IsNumber()
  discountPrice?: number;

  @IsOptional()
  @IsNumber()
  stock?: number;

  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}

export class CreateProductDto {
  @IsNotEmpty()
  name: string;

  @IsUUID()
  categoryId: string;

  @IsOptional()
  description?: string;

  @IsNumber()
  @Min(0)
  basePrice: number;

  @IsOptional()
  @IsNumber()
  discountPrice?: number;

  @IsOptional()
  @IsNumber()
  stock?: number;

  @IsOptional()
  unit?: string;

  @IsOptional()
  weight?: string;

  @IsOptional()
  @IsArray()
  images?: string[];

  @IsOptional()
  @IsBoolean()
  isFeatured?: boolean;

  @IsOptional()
  @IsBoolean()
  isBestSeller?: boolean;

  @IsOptional()
  @IsBoolean()
  isTrending?: boolean;

  @IsOptional()
  @IsArray()
  tags?: string[];

  @IsOptional()
  @Type(() => CreateProductVariantDto)
  variants?: CreateProductVariantDto[];
}

export class UpdateProductDto {
  @IsOptional()
  name?: string;

  @IsOptional()
  categoryId?: string;

  @IsOptional()
  description?: string;

  @IsOptional()
  basePrice?: number;

  @IsOptional()
  discountPrice?: number;

  @IsOptional()
  stock?: number;

  @IsOptional()
  unit?: string;

  @IsOptional()
  weight?: string;

  @IsOptional()
  images?: string[];

  @IsOptional()
  isActive?: boolean;

  @IsOptional()
  isFeatured?: boolean;

  @IsOptional()
  isBestSeller?: boolean;

  @IsOptional()
  isTrending?: boolean;

  @IsOptional()
  tags?: string[];
}

export class ProductFilterDto {
  @IsOptional()
  categoryId?: string;

  @IsOptional()
  search?: string;

  @IsOptional()
  isFeatured?: boolean;

  @IsOptional()
  isBestSeller?: boolean;

  @IsOptional()
  isTrending?: boolean;

  @IsOptional()
  minPrice?: number;

  @IsOptional()
  maxPrice?: number;

  @IsOptional()
  sortBy?: string;

  @IsOptional()
  sortOrder?: 'asc' | 'desc';
}
