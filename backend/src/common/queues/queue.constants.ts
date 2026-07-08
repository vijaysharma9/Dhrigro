export const QUEUE_NAMES = {
  NOTIFICATIONS: 'notifications',
  EXPORTS: 'exports',
  PAYMENT_RECONCILIATION: 'payment-reconciliation',
  ANALYTICS: 'analytics',
  STOCK_ALERTS: 'stock-alerts',
} as const;

export type QueueName = (typeof QUEUE_NAMES)[keyof typeof QUEUE_NAMES];

export interface QueueJobPayload {
  type: string;
  data: Record<string, unknown>;
  correlationId?: string;
}
