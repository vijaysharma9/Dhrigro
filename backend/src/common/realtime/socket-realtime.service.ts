import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  DeliveryRealtimeEvent,
  IDeliveryRealtime,
} from './delivery-realtime.interface';
import { RealtimeEvent, REALTIME_ROOMS } from './realtime-events';

export type RealtimeBroadcast = (event: RealtimeEvent) => void;

@Injectable()
export class SocketRealtimeService implements IDeliveryRealtime {
  private readonly logger = new Logger(SocketRealtimeService.name);
  private broadcastFn: RealtimeBroadcast | null = null;
  private connectionCount = 0;

  constructor(private config: ConfigService) {}

  /** Called by RealtimeGateway after init. */
  setBroadcast(fn: RealtimeBroadcast) {
    this.broadcastFn = fn;
  }

  setConnectionCount(count: number) {
    this.connectionCount = count;
  }

  getConnectionCount(): number {
    return this.connectionCount;
  }

  isEnabled(): boolean {
    return this.config.get<string>('realtime.enabled') !== 'false';
  }

  async emit(event: DeliveryRealtimeEvent): Promise<void> {
    const mapped: RealtimeEvent = {
      type:
        event.type === 'assignment.created' || event.type === 'assignment.updated'
          ? 'order_assigned'
          : event.type === 'order.delivered'
            ? 'order_updated'
            : 'partner_location',
      payload: {
        orderId: event.orderId,
        partnerId: event.partnerId,
        ...event.payload,
      },
      room: REALTIME_ROOMS.admin,
    };
    await this.publish(mapped);
  }

  async publish(event: RealtimeEvent): Promise<void> {
    if (!this.isEnabled()) return;

    const enriched: RealtimeEvent = {
      ...event,
      timestamp: event.timestamp ?? new Date().toISOString(),
      room: event.room ?? REALTIME_ROOMS.admin,
    };

    if (this.broadcastFn) {
      this.broadcastFn(enriched);
    } else {
      this.logger.debug(`Realtime (no gateway): ${enriched.type}`);
    }
  }
}
