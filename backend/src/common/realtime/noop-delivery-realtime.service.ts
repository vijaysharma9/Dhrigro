import { Injectable } from '@nestjs/common';
import {
  DeliveryRealtimeEvent,
  IDeliveryRealtime,
} from './delivery-realtime.interface';

@Injectable()
export class NoopDeliveryRealtimeService implements IDeliveryRealtime {
  isEnabled(): boolean {
    return false;
  }

  async emit(_event: DeliveryRealtimeEvent): Promise<void> {
    // WebSocket gateway will plug in here later.
  }
}
