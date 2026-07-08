import { Global, Module } from '@nestjs/common';
import { AuthModule } from '../../modules/auth/auth.module';
import { DELIVERY_REALTIME } from './delivery-realtime.interface';
import { RealtimeGateway } from './realtime.gateway';
import { SocketRealtimeService } from './socket-realtime.service';

@Global()
@Module({
  imports: [AuthModule],
  providers: [
    SocketRealtimeService,
    RealtimeGateway,
    {
      provide: DELIVERY_REALTIME,
      useExisting: SocketRealtimeService,
    },
  ],
  exports: [DELIVERY_REALTIME, SocketRealtimeService],
})
export class RealtimeModule {}
