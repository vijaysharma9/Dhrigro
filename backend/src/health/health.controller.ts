import { Controller, Get, HttpStatus, Res } from '@nestjs/common';
import { Response } from 'express';
import { Public } from '../common/decorators/public.decorator';
import { RedisService } from '../redis/redis.service';
import { HealthService } from './health.service';

@Controller('health')
export class HealthController {
  constructor(
    private readonly health: HealthService,
    private readonly redis: RedisService,
  ) {}

  /** Primary liveness + summary (backward compatible path). */
  @Public()
  @Get()
  async liveness() {
    return this.health.buildSummary();
  }

  /** Database connectivity check. */
  @Public()
  @Get('database')
  async databaseHealth() {
    const db = await this.health.checkDatabase();
    return {
      status: db.status,
      database: db.status,
      latencyMs: db.latencyMs,
      environment: this.health.environment,
      timestamp: new Date().toISOString(),
    };
  }

  /** Backward-compatible alias for database check. */
  @Public()
  @Get('db')
  async dbHealth() {
    const db = await this.health.checkDatabase();
    return {
      status: db.status,
      latencyMs: db.latencyMs,
    };
  }

  /** Build / release version metadata. */
  @Public()
  @Get('version')
  version() {
    return this.health.versionPayload();
  }

  /** Readiness probe — returns 503 when dependencies are unavailable. */
  @Public()
  @Get('ready')
  async readiness(@Res({ passthrough: true }) res: Response) {
    const checks: Record<string, string> = { api: 'ok' };
    const db = await this.health.checkDatabase();
    checks.database = db.status;
    checks.redis = this.redis.isReady() ? 'ok' : 'degraded';

    const healthy = checks.database === 'ok';
    if (!healthy) {
      res.status(HttpStatus.SERVICE_UNAVAILABLE);
    }

    return {
      status: healthy ? 'ready' : 'not_ready',
      checks,
      uptime: this.health.uptime,
      version: this.health.version,
      environment: this.health.environment,
      timestamp: new Date().toISOString(),
    };
  }
}
