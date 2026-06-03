import { DeliveryOtpService } from './delivery-otp.service';

describe('DeliveryOtpService', () => {
  const prisma = {
    order: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
  };

  let service: DeliveryOtpService;

  beforeEach(() => {
    service = new DeliveryOtpService(prisma as never);
  });

  it('generates 6 digit otp', () => {
    const otp = service.generateOtp();
    expect(otp).toMatch(/^\d{6}$/);
  });

  it('verify fails when expired', async () => {
    prisma.order.findUnique.mockResolvedValue({
      deliveryOtp: '123456',
      deliveryOtpExpiresAt: new Date(Date.now() - 1000),
    });
    const ok = await service.verifyOrderOtp('order-1', '123456');
    expect(ok).toBe(false);
  });
});
