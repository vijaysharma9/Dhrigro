import { Module } from '@nestjs/common';
import { AdminService } from './admin.service';
import { AdminController } from './admin.controller';
import { AdminOrdersService } from './services/admin-orders.service';
import { AdminUsersService } from './services/admin-users.service';
import { AdminInventoryService } from './services/admin-inventory.service';
import { AdminReportsService } from './services/admin-reports.service';
import { AdminDeliveryService } from './services/admin-delivery.service';
import { OrdersModule } from '../orders/orders.module';
import { CouponsModule } from '../coupons/coupons.module';
import { BannersModule } from '../banners/banners.module';
import { DeliveryModule } from '../delivery/delivery.module';
import { DeliveryAssignmentsModule } from '../delivery-assignments/delivery-assignments.module';

@Module({
  imports: [
    OrdersModule,
    CouponsModule,
    BannersModule,
    DeliveryModule,
    DeliveryAssignmentsModule,
  ],
  controllers: [AdminController],
  providers: [
    AdminService,
    AdminOrdersService,
    AdminUsersService,
    AdminInventoryService,
    AdminReportsService,
    AdminDeliveryService,
  ],
  exports: [AdminService],
})
export class AdminModule {}
