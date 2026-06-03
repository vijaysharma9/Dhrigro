import { Type } from 'class-transformer';
import {
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Max,
  Min,
} from 'class-validator';

export class AssignDeliveryDto {
  @IsUUID()
  orderId: string;

  @IsUUID()
  deliveryPartnerId: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class ReassignDeliveryDto {
  @IsUUID()
  orderId: string;

  @IsUUID()
  deliveryPartnerId: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class DeliverOrderDto {
  @IsString()
  @Length(4, 8)
  otp: string;
}

export class FailDeliveryDto {
  @IsString()
  failureReason: string;
}

export class PartnerOrdersQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number = 20;
}
