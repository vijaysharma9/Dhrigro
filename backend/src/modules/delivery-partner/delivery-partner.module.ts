import { Module } from '@nestjs/common';
import { DeliveryPartnerController } from './delivery-partner.controller';
import { DeliveryPartnerService } from './delivery-partner.service';
import { DeliveryAssignmentsModule } from '../delivery-assignments/delivery-assignments.module';

@Module({
  imports: [DeliveryAssignmentsModule],
  controllers: [DeliveryPartnerController],
  providers: [DeliveryPartnerService],
  exports: [DeliveryPartnerService],
})
export class DeliveryPartnerModule {}
