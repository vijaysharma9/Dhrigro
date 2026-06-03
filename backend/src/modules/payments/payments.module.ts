import { Module } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { PaymentsController } from './payments.controller';
import { RazorpayService } from './razorpay.service';
import { PaymentAuditService } from './payment-audit.service';
import { PaymentIdempotencyService } from './payment-idempotency.service';
import { PaymentReconciliationService } from './payment-reconciliation.service';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  controllers: [PaymentsController],
  providers: [
    PaymentsService,
    RazorpayService,
    PaymentAuditService,
    PaymentIdempotencyService,
    PaymentReconciliationService,
  ],
  exports: [
    PaymentsService,
    RazorpayService,
    PaymentReconciliationService,
  ],
})
export class PaymentsModule {}
