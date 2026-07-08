import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';

const bootedAt = Date.now();

@Injectable()
export class HealthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly config: ConfigService,
  ) {}

  get uptime(): number {
    return Math.floor((Date.now() - bootedAt) / 1000);
  }

  get version(): string {
    return this.config.get<string>('app.version') || '0.0.1';
  }

  get environment(): string {
    return this.config.get<string>('nodeEnv') || 'development';
  }

  get service(): string {
    return this.config.get<string>('app.name') || 'dhrigro-api';
  }

  async checkDatabase(): Promise<{
    status: 'ok' | 'error';
    latencyMs: number;
  }> {
    const start = Date.now();
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return { status: 'ok', latencyMs: Date.now() - start };
    } catch {
      return { status: 'error', latencyMs: Date.now() - start };
    }
  }

  async buildSummary() {
    const db = await this.checkDatabase();
    return {
      status: db.status === 'ok' ? 'ok' : 'degraded',
      uptime: this.uptime,
      version: this.version,
      database: db.status,
      environment: this.environment,
      service: this.service,
      timestamp: new Date().toISOString(),
    };
  }

  versionPayload() {
    return {
      status: 'ok',
      version: this.version,
      environment: this.environment,
      service: this.service,
      uptime: this.uptime,
      timestamp: new Date().toISOString(),
    };
  }
}
