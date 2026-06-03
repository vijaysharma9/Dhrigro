import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client: Redis | null = null;

  constructor(private configService: ConfigService) {}

  async onModuleInit() {
    const enabled = this.configService.get<boolean>('redis.enabled');
    const url = this.configService.get<string>('redis.url');
    if (!enabled || !url) {
      this.logger.warn('Redis disabled — caching and OTP store use fallbacks');
      return;
    }

    try {
      this.client = new Redis(url, { maxRetriesPerRequest: 3 });
      await this.client.ping();
      this.logger.log('Redis connected');
    } catch (err) {
      this.logger.warn(`Redis unavailable: ${(err as Error).message}`);
      this.client = null;
    }
  }

  async onModuleDestroy() {
    if (this.client) {
      await this.client.quit();
    }
  }

  isReady(): boolean {
    return this.client?.status === 'ready';
  }

  getClient(): Redis | null {
    return this.client;
  }

  async get(key: string): Promise<string | null> {
    if (!this.client) return null;
    return this.client.get(key);
  }

  async set(key: string, value: string, ttlSeconds?: number): Promise<void> {
    if (!this.client) return;
    if (ttlSeconds) {
      await this.client.setex(key, ttlSeconds, value);
    } else {
      await this.client.set(key, value);
    }
  }

  async del(key: string): Promise<void> {
    if (!this.client) return;
    await this.client.del(key);
  }

  async setNx(
    key: string,
    value: string,
    ttlSeconds: number,
  ): Promise<boolean> {
    if (!this.client) return true;
    const result = await this.client.set(key, value, 'EX', ttlSeconds, 'NX');
    return result === 'OK';
  }
}
