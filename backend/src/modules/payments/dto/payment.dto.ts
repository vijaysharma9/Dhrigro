import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateRazorpayOrderDto {
  @IsNotEmpty()
  @IsString()
  orderId: string;
}

export class VerifyRazorpayPaymentDto {
  @IsNotEmpty()
  @IsString()
  orderId: string;

  @IsNotEmpty()
  @IsString()
  razorpayOrderId: string;

  @IsNotEmpty()
  @IsString()
  razorpayPaymentId: string;

  @IsNotEmpty()
  @IsString()
  razorpaySignature: string;
}

export class PaymentFailedDto {
  @IsNotEmpty()
  @IsString()
  orderId: string;

  @IsOptional()
  @IsString()
  reason?: string;
}
