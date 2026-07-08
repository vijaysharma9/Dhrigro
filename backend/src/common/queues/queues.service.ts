import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Queue, Worker, Job } from 'bullmq';
import { MetricsService } from '../metrics/metrics.service';
import { QUEUE_NAMES, QueueJobPayload } from './queue.constants';

export interface QueueStats {
  name: string;
  waiting: number;
  active: number;
  completed: number;
  failed: number;
  delayed: number;
}

@Injectable()
export class QueuesService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(QueuesService.name);
  private readonly queues = new Map<string, Queue>();
  private readonly workers: Worker[] = [];
  private enabled = false;

  constructor(
    private config: ConfigService,
    private metrics: MetricsService,
  ) {}

  onModuleInit() {
    this.enabled = this.config.get<boolean>('queues.enabled') !== false;
    if (!this.enabled) {
      this.logger.warn('BullMQ queues disabled');
      return;
    }

    const connection = { url: this.config.get<string>('redis.url') };

    for (const name of Object.values(QUEUE_NAMES)) {
      const queue = new Queue(name, {
        connection,
        defaultJobOptions: {
          attempts: 3,
          backoff: { type: 'exponential', delay: 2000 },
          removeOnComplete: 100,
          removeOnFail: 500,
        },
      });
      this.queues.set(name, queue);

      const worker = new Worker(
        name,
        async (job: Job<QueueJobPayload>) => this.processJob(name, job),
        { connection, concurrency: 2 },
      );

      worker.on('failed', (job, err) => {
        this.logger.error(`Job ${job?.id} in ${name} failed: ${err.message}`);
      });

      this.workers.push(worker);
    }

    this.logger.log(`BullMQ initialized (${this.queues.size} queues)`);
  }

  async onModuleDestroy() {
    await Promise.all([
      ...Array.from(this.queues.values()).map((q) => q.close()),
      ...this.workers.map((w) => w.close()),
    ]);
  }

  isEnabled(): boolean {
    return this.enabled;
  }

  async enqueue(
    queueName: string,
    payload: QueueJobPayload,
    opts?: { delay?: number; jobId?: string },
  ): Promise<string | null> {
    if (!this.enabled) {
      this.logger.debug(`Queue disabled — inline: ${queueName}/${payload.type}`);
      await this.processJob(queueName, { data: payload } as Job<QueueJobPayload>);
      return null;
    }

    const queue = this.queues.get(queueName);
    if (!queue) throw new Error(`Unknown queue: ${queueName}`);

    const job = await queue.add(payload.type, payload, {
      delay: opts?.delay,
      jobId: opts?.jobId,
    });
    return job.id ?? null;
  }

  async getStats(): Promise<QueueStats[]> {
    const stats: QueueStats[] = [];

    for (const [name, queue] of this.queues) {
      const counts = await queue.getJobCounts(
        'waiting',
        'active',
        'completed',
        'failed',
        'delayed',
      );
      stats.push({
        name,
        waiting: counts.waiting ?? 0,
        active: counts.active ?? 0,
        completed: counts.completed ?? 0,
        failed: counts.failed ?? 0,
        delayed: counts.delayed ?? 0,
      });
      this.metrics.queueDepth.set({ queue: name }, counts.waiting ?? 0);
    }

    if (!this.enabled) {
      return Object.values(QUEUE_NAMES).map((name) => ({
        name,
        waiting: 0,
        active: 0,
        completed: 0,
        failed: 0,
        delayed: 0,
      }));
    }

    return stats;
  }

  private async processJob(queueName: string, job: Job<QueueJobPayload>) {
    const { type, data, correlationId } = job.data;
    this.logger.log(
      JSON.stringify({
        level: 'info',
        msg: 'queue_job',
        queue: queueName,
        type,
        correlationId,
        jobId: job.id,
      }),
    );

    switch (type) {
      case 'send_notification':
        // NotificationsService integration point
        break;
      case 'export_csv':
        break;
      case 'reconcile_payment':
        break;
      case 'aggregate_analytics':
        break;
      case 'stock_alert':
        break;
      default:
        this.logger.warn(`Unhandled job type: ${type}`);
    }

    return { ok: true, queue: queueName, type, data };
  }
}
