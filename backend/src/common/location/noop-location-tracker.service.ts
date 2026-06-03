import { Injectable, Logger } from '@nestjs/common';
import {
  ILocationTracker,
  LocationUpdatePayload,
} from './location-tracker.interface';

@Injectable()
export class NoopLocationTrackerService implements ILocationTracker {
  private readonly logger = new Logger(NoopLocationTrackerService.name);

  isLiveTrackingEnabled(): boolean {
    return false;
  }

  async recordPartnerLocation(payload: LocationUpdatePayload): Promise<void> {
    this.logger.debug(
      `Location tracking disabled — skipped update for ${payload.userId}`,
    );
  }
}
