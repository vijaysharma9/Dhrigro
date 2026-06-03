import { Module } from '@nestjs/common';
import { DeliveryAssignmentsService } from './delivery-assignments.service';
import { DeliveryOtpService } from './delivery-otp.service';
import { OrdersModule } from '../orders/orders.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [OrdersModule, NotificationsModule],
  providers: [DeliveryAssignmentsService, DeliveryOtpService],
  exports: [DeliveryAssignmentsService, DeliveryOtpService],
})
export class DeliveryAssignmentsModule {}
