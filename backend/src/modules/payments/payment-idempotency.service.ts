import { Injectable } from '@nestjs/common';
import { RedisService } from '../../redis/redis.service';
import { AppError, ErrorCode } from '../../common/errors/app-error';
import { HttpStatus } from '@nestjs/common';

const PAYMENT_LOCK_PREFIX = 'dr:pay:lock:';
const WEBHOOK_PREFIX = 'dr:webhook:';

@Injectable()
export class PaymentIdempotencyService {
  constructor(private redis: RedisService) {}

  async acquirePaymentLock(orderId: string, ttlSeconds = 120): Promise<void> {
    const key = `${PAYMENT_LOCK_PREFIX}${orderId}`;
    const ok = await this.redis.setNx(key, '1', ttlSeconds);
    if (!ok) {
      throw new AppError(
        ErrorCode.PAYMENT_DUPLICATE,
        'Payment processing already in progress for this order',
        HttpStatus.CONFLICT,
      );
    }
  }

  async releasePaymentLock(orderId: string): Promise<void> {
    await this.redis.del(`${PAYMENT_LOCK_PREFIX}${orderId}`);
  }

  /** Returns true if webhook event is new; false if replay. */
  async registerWebhookEvent(eventId: string, ttlSeconds = 86400): Promise<boolean> {
    if (!eventId) return true;
    const key = `${WEBHOOK_PREFIX}${eventId}`;
    return this.redis.setNx(key, '1', ttlSeconds);
  }
}
