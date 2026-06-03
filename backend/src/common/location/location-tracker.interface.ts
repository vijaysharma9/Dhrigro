export const LOCATION_TRACKER = Symbol('LOCATION_TRACKER');

/** Future-ready location updates (live tracking disabled). */
export interface LocationUpdatePayload {
  userId: string;
  latitude: number;
  longitude: number;
  recordedAt?: Date;
}

export interface ILocationTracker {
  /** Persist partner coordinates — noop until live tracking is enabled. */
  recordPartnerLocation(payload: LocationUpdatePayload): Promise<void>;
  /** Subscribe to partner location stream — not implemented yet. */
  isLiveTrackingEnabled(): boolean;
}
