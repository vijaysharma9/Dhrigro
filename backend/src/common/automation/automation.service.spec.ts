import { AutomationService } from './automation.service';

describe('AutomationService', () => {
  const prisma = {
    user: { findUnique: jest.fn() },
    order: { findMany: jest.fn().mockResolvedValue([]) },
    product: { findMany: jest.fn().mockResolvedValue([]) },
  };
  const queues = { enqueue: jest.fn() };
  const realtime = { publish: jest.fn() };

  let service: AutomationService;

  beforeEach(() => {
    service = new AutomationService(
      prisma as never,
      queues as never,
      realtime as never,
    );
    jest.clearAllMocks();
  });

  it('returns default automation rules', () => {
    const rules = service.getRules();
    expect(rules.some((r) => r.id === 'auto_delayed')).toBe(true);
  });

  it('updates rule enabled flag', () => {
    const updated = service.updateRule('auto_cancel_cod', true);
    expect(updated?.enabled).toBe(true);
  });

  it('skips VIP priority when rule disabled', async () => {
    service.updateRule('auto_vip_priority', false);
    await service.onOrderCreated('order-1', 'user-1');
    expect(prisma.user.findUnique).not.toHaveBeenCalled();
  });

  it('checks VIP points when rule enabled', async () => {
    service.updateRule('auto_vip_priority', true);
    prisma.user.findUnique.mockResolvedValue({ loyaltyPoints: 600 });
    await service.onOrderCreated('order-1', 'user-1');
    expect(prisma.user.findUnique).toHaveBeenCalled();
  });
});
