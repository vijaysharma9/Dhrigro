import { Global, Module } from '@nestjs/common';
import { LOCATION_TRACKER } from './location-tracker.interface';
import { NoopLocationTrackerService } from './noop-location-tracker.service';

@Global()
@Module({
  providers: [
    {
      provide: LOCATION_TRACKER,
      useClass: NoopLocationTrackerService,
    },
  ],
  exports: [LOCATION_TRACKER],
})
export class LocationModule {}
