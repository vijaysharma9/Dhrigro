import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';

export class ImportProductRowDto {
  @IsNotEmpty()
  @IsString()
  name: string;

  @IsOptional()
  @IsUUID()
  categoryId?: string;

  /** Category display name (used when categoryId is omitted). */
  @IsOptional()
  @IsString()
  category?: string;

  /** Subcategory name/slug (resolved within the parent category). */
  @IsOptional()
  @IsString()
  subcategory?: string;

  /** Free-text alias that maps to a category/subcategory (e.g. "veg", "atta"). */
  @IsOptional()
  @IsString()
  alias?: string;

  @IsNumber()
  @Min(0)
  basePrice: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  discountPrice?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  stock?: number;

  @IsOptional()
  @IsString()
  unit?: string;

  @IsOptional()
  @IsString()
  sku?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  imageUrl?: string;

  @IsOptional()
  @IsBoolean()
  isFeatured?: boolean;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class ImportProductsDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ImportProductRowDto)
  rows: ImportProductRowDto[];

  /**
   * How to match existing products during import:
   * - sku_or_name (default): SKU first, then name within the same category
   * - sku: SKU only
   * - name: name within the same category only
   */
  @IsOptional()
  @IsString()
  matchBy?: 'sku_or_name' | 'sku' | 'name';
}
