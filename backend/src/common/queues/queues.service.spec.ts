import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { QueuesService } from './queues.service';
import { MetricsService } from '../metrics/metrics.service';

describe('QueuesService', () => {
  let service: QueuesService;

  const metricsMock = {
    queueDepth: { set: jest.fn() },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        QueuesService,
        {
          provide: ConfigService,
          useValue: {
            get: (key: string) => {
              if (key === 'queues.enabled') return false;
              if (key === 'redis.url') return 'redis://localhost:6379';
              return undefined;
            },
          },
        },
        { provide: MetricsService, useValue: metricsMock },
      ],
    }).compile();

    service = module.get(QueuesService);
    service.onModuleInit();
  });

  it('runs inline when queues disabled', async () => {
    const id = await service.enqueue('notifications', {
      type: 'send_notification',
      data: { userId: 'u1' },
    });
    expect(id).toBeNull();
  });

  it('returns zero stats when disabled', async () => {
    const stats = await service.getStats();
    expect(stats.length).toBeGreaterThan(0);
    expect(stats[0].waiting).toBe(0);
  });
});
