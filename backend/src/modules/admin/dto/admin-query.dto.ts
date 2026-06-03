import { Type } from 'class-transformer';
import {
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';
import { OrderStatus, PaymentMethod } from '@prisma/client';

export class AdminPaginationDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;

  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsString()
  sortBy?: string;

  @IsOptional()
  @IsString()
  sortOrder?: 'asc' | 'desc' = 'desc';
}

export class AdminOrdersQueryDto extends AdminPaginationDto {
  @IsOptional()
  @IsEnum(OrderStatus)
  status?: OrderStatus;

  @IsOptional()
  @IsEnum(PaymentMethod)
  paymentMethod?: PaymentMethod;

  @IsOptional()
  @IsDateString()
  fromDate?: string;

  @IsOptional()
  @IsDateString()
  toDate?: string;
}

export class AdminUsersQueryDto extends AdminPaginationDto {
  @IsOptional()
  @IsString()
  role?: string;

  @IsOptional()
  @Type(() => Boolean)
  isActive?: boolean;
}

export class AdminInventoryQueryDto extends AdminPaginationDto {
  @IsOptional()
  @Type(() => Boolean)
  lowStock?: boolean;

  @IsOptional()
  @Type(() => Number)
  lowStockThreshold?: number = 10;
}

export class AdminReportsQueryDto {
  @IsOptional()
  @IsDateString()
  fromDate?: string;

  @IsOptional()
  @IsDateString()
  toDate?: string;
}
