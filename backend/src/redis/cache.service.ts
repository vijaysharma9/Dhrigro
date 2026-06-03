import { Injectable } from '@nestjs/common';
import { RedisService } from './redis.service';

const PREFIX = 'dr:cache:';

@Injectable()
export class CacheService {
  constructor(private redis: RedisService) {}

  private key(k: string) {
    return `${PREFIX}${k}`;
  }

  async get<T>(key: string): Promise<T | null> {
    const raw = await this.redis.get(this.key(key));
    if (!raw) return null;
    try {
      return JSON.parse(raw) as T;
    } catch {
      return null;
    }
  }

  async set(key: string, value: unknown, ttlSeconds: number): Promise<void> {
    await this.redis.set(
      this.key(key),
      JSON.stringify(value),
      ttlSeconds,
    );
  }

  async invalidate(key: string): Promise<void> {
    await this.redis.del(this.key(key));
  }

  async invalidatePattern(pattern: string): Promise<void> {
    const client = this.redis.getClient();
    if (!client) return;
    const keys = await client.keys(`${PREFIX}${pattern}`);
    if (keys.length) await client.del(...keys);
  }

  async wrap<T>(
    key: string,
    ttlSeconds: number,
    factory: () => Promise<T>,
  ): Promise<T> {
    const cached = await this.get<T>(key);
    if (cached !== null) return cached;
    const fresh = await factory();
    await this.set(key, fresh, ttlSeconds);
    return fresh;
  }
}
