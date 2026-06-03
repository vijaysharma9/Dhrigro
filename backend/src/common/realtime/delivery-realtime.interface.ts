export const DELIVERY_REALTIME = Symbol('DELIVERY_REALTIME');

export interface DeliveryRealtimeEvent {
  type:
    | 'assignment.created'
    | 'assignment.updated'
    | 'location.updated'
    | 'order.delivered';
  orderId: string;
  partnerId?: string;
  payload?: Record<string, unknown>;
}

/** WebSocket-ready abstraction — events are no-op until realtime is enabled. */
export interface IDeliveryRealtime {
  isEnabled(): boolean;
  emit(event: DeliveryRealtimeEvent): Promise<void>;
}
