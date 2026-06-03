import { Global, Module } from '@nestjs/common';
import { DELIVERY_REALTIME } from './delivery-realtime.interface';
import { NoopDeliveryRealtimeService } from './noop-delivery-realtime.service';

@Global()
@Module({
  providers: [
    {
      provide: DELIVERY_REALTIME,
      useClass: NoopDeliveryRealtimeService,
    },
  ],
  exports: [DELIVERY_REALTIME],
})
export class RealtimeModule {}
