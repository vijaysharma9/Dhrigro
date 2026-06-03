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
import { UserRole } from '@prisma/client';
import { DeliveryPartnerService } from './delivery-partner.service';
import { DeliveryAssignmentsService } from '../delivery-assignments/delivery-assignments.service';
import {
  UpdateAvailabilityDto,
  UpdateDeliveryProfileDto,
  UpdateLocationDto,
} from './dto/delivery-partner.dto';
import {
  DeliverOrderDto,
  FailDeliveryDto,
  PartnerOrdersQueryDto,
} from '../delivery-assignments/dto/delivery-assignment.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Delivery Partner')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.DELIVERY_PARTNER)
@Controller('delivery')
export class DeliveryPartnerController {
  constructor(
    private partnerService: DeliveryPartnerService,
    private assignmentsService: DeliveryAssignmentsService,
  ) {}

  @Get('profile')
  getProfile(@CurrentUser('id') userId: string) {
    return this.partnerService.getOrCreateProfile(userId);
  }

  @Patch('profile')
  updateProfile(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateDeliveryProfileDto,
  ) {
    return this.partnerService.updateProfile(userId, dto);
  }

  @Patch('availability')
  updateAvailability(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateAvailabilityDto,
  ) {
    return this.partnerService.updateAvailability(userId, dto);
  }

  @Patch('location')
  updateLocation(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateLocationDto,
  ) {
    return this.partnerService.recordLocation(
      userId,
      dto.latitude,
      dto.longitude,
    );
  }

  @Get('orders/assigned')
  assignedOrders(
    @CurrentUser('id') userId: string,
    @Query() query: PartnerOrdersQueryDto,
  ) {
    return this.assignmentsService.listAssignedOrders(
      userId,
      query.page,
      query.limit,
    );
  }

  @Get('orders/history')
  historyOrders(
    @CurrentUser('id') userId: string,
    @Query() query: PartnerOrdersQueryDto,
  ) {
    return this.assignmentsService.listDeliveryHistory(
      userId,
      query.page,
      query.limit,
    );
  }

  @Get('orders/:id')
  getOrder(
    @CurrentUser('id') userId: string,
    @Param('id') orderId: string,
  ) {
    return this.assignmentsService.getPartnerOrder(userId, orderId);
  }

  @Patch('orders/:id/accept')
  acceptOrder(
    @CurrentUser('id') userId: string,
    @Param('id') orderId: string,
  ) {
    return this.assignmentsService.acceptOrder(userId, orderId);
  }

  @Patch('orders/:id/pick')
  pickOrder(
    @CurrentUser('id') userId: string,
    @Param('id') orderId: string,
  ) {
    return this.assignmentsService.pickOrder(userId, orderId);
  }

  @Patch('orders/:id/start')
  startOrder(
    @CurrentUser('id') userId: string,
    @Param('id') orderId: string,
  ) {
    return this.assignmentsService.startDelivery(userId, orderId);
  }

  @Patch('orders/:id/deliver')
  deliverOrder(
    @CurrentUser('id') userId: string,
    @Param('id') orderId: string,
    @Body() dto: DeliverOrderDto,
  ) {
    return this.assignmentsService.completeDelivery(userId, orderId, dto.otp);
  }

  @Patch('orders/:id/fail')
  failOrder(
    @CurrentUser('id') userId: string,
    @Param('id') orderId: string,
    @Body() dto: FailDeliveryDto,
  ) {
    return this.assignmentsService.failDelivery(
      userId,
      orderId,
      dto.failureReason,
    );
  }

  @Post('orders/:id/resend-otp')
  resendOtp(
    @CurrentUser('id') userId: string,
    @Param('id') orderId: string,
  ) {
    return this.assignmentsService.resendDeliveryOtp(userId, orderId);
  }

  @Get('earnings')
  getEarnings(@CurrentUser('id') userId: string) {
    return this.partnerService.getEarnings(userId);
  }
}
