/** Canonical realtime event types for WebSocket + admin invalidation. */
export type RealtimeEventType =
  | 'order_created'
  | 'order_updated'
  | 'order_assigned'
  | 'payment_failed'
  | 'partner_location'
  | 'stock_low'
  | 'notification_created';

export interface RealtimeEvent {
  type: RealtimeEventType;
  payload: Record<string, unknown>;
  /** Target room — defaults to admin broadcast. */
  room?: string;
  timestamp?: string;
}

export const REALTIME_ROOMS = {
  admin: 'admin',
  partner: (id: string) => `partner:${id}`,
  order: (id: string) => `order:${id}`,
} as const;
