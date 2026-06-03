import { Body, Controller, Get, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { DeliveryType, UserRole } from '@prisma/client';
import { DeliveryService } from './delivery.service';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';

@ApiTags('Delivery')
@Controller('delivery')
export class DeliveryController {
  constructor(private deliveryService: DeliveryService) {}

  @Public()
  @Get('settings')
  getSettings() {
    return this.deliveryService.getSettings();
  }

  @Public()
  @Get('slots')
  getSlots(@Query('type') type?: DeliveryType) {
    return this.deliveryService.getSlots(type);
  }

  @Public()
  @Get('check-pincode')
  checkPincode(@Query('pincode') pincode: string) {
    return this.deliveryService.checkPincode(pincode);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('calculate-fees')
  calculateFees(
    @Body() body: { subtotal: number; deliveryType?: DeliveryType },
  ) {
    return this.deliveryService.calculateFees(
      body.subtotal,
      body.deliveryType,
    );
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @Patch('settings')
  updateSettings(@Body() body: Record<string, unknown>) {
    return this.deliveryService.updateSettings(body);
  }
}
