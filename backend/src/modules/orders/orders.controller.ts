import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { DeliveryType, OrderStatus, PaymentMethod, UserRole } from '@prisma/client';
import { OrdersService } from './orders.service';
import { PaginationDto } from '../../common/dto/pagination.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Orders')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('orders')
export class OrdersController {
  constructor(private ordersService: OrdersService) {}

  @Post()
  placeOrder(
    @CurrentUser('id') userId: string,
    @Body()
    body: {
      addressId: string;
      deliverySlotId?: string;
      deliveryType?: DeliveryType;
      paymentMethod?: PaymentMethod;
      deliveryInstructions?: string;
    },
  ) {
    return this.ordersService.placeOrder(userId, body);
  }

  @Get()
  getMyOrders(
    @CurrentUser('id') userId: string,
    @Query() pagination: PaginationDto,
  ) {
    return this.ordersService.getUserOrders(userId, pagination);
  }

  @UseGuards(RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @Get('admin/all')
  adminGetAll(
    @Query() pagination: PaginationDto,
    @Query('status') status?: OrderStatus,
  ) {
    return this.ordersService.getAllOrders(pagination, status);
  }

  @UseGuards(RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @Patch('admin/:id/status')
  updateStatus(
    @Param('id') id: string,
    @Body()
    body: { status: OrderStatus; note?: string; cancelledReason?: string },
  ) {
    return this.ordersService.updateStatus(
      id,
      body.status,
      body.note,
      body.cancelledReason,
    );
  }

  @Get(':id')
  getOrder(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
  ) {
    return this.ordersService.getOrder(userId, id);
  }

  @Post(':id/reorder')
  reorder(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
  ) {
    return this.ordersService.reorder(userId, id);
  }
}
