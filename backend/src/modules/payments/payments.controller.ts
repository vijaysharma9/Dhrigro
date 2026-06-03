import {
  BadRequestException,
  Body,
  Controller,
  Headers,
  Post,
  RawBodyRequest,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { PaymentsService } from './payments.service';
import {
  CreateRazorpayOrderDto,
  PaymentFailedDto,
  VerifyRazorpayPaymentDto,
} from './dto/payment.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('Payments')
@Controller('payments')
export class PaymentsController {
  constructor(private paymentsService: PaymentsService) {}

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('razorpay/create-order')
  createRazorpayOrder(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateRazorpayOrderDto,
  ) {
    return this.paymentsService.createRazorpayOrder(userId, dto.orderId);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('razorpay/verify')
  verifyPayment(
    @CurrentUser('id') userId: string,
    @Body() dto: VerifyRazorpayPaymentDto,
  ) {
    return this.paymentsService.verifyRazorpayPayment(userId, dto);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('razorpay/failed')
  paymentFailed(
    @CurrentUser('id') userId: string,
    @Body() dto: PaymentFailedDto,
  ) {
    return this.paymentsService.markPaymentFailed(
      userId,
      dto.orderId,
      dto.reason,
    );
  }

  @Public()
  @Post('razorpay/webhook')
  webhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('x-razorpay-signature') signature: string,
  ) {
    const rawBody = req.rawBody;
    if (!rawBody) {
      throw new BadRequestException('Raw body required for webhook verification');
    }
    return this.paymentsService.handleWebhook(rawBody, signature);
  }
}
