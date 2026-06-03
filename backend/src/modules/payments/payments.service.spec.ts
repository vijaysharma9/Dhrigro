import { Test, TestingModule } from '@nestjs/testing';
import { PaymentsService } from './payments.service';
import { PrismaService } from '../../prisma/prisma.service';
import { RazorpayService } from './razorpay.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PaymentAuditService } from './payment-audit.service';
import { PaymentIdempotencyService } from './payment-idempotency.service';

describe('PaymentsService', () => {
  let service: PaymentsService;

  const prismaMock = {
    order: {
      findFirst: jest.fn(),
      update: jest.fn(),
    },
    paymentAuditLog: { create: jest.fn() },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PaymentsService,
        { provide: PrismaService, useValue: prismaMock },
        {
          provide: RazorpayService,
          useValue: { getKeyId: () => 'key', createOrder: jest.fn(), verifyPaymentSignature: () => true },
        },
        {
          provide: NotificationsService,
          useValue: { sendOrderStatusNotification: jest.fn() },
        },
        {
          provide: PaymentAuditService,
          useValue: { log: jest.fn() },
        },
        {
          provide: PaymentIdempotencyService,
          useValue: {
            acquirePaymentLock: jest.fn(),
            releasePaymentLock: jest.fn(),
            registerWebhookEvent: jest.fn().mockResolvedValue(true),
          },
        },
      ],
    }).compile();

    service = module.get(PaymentsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
