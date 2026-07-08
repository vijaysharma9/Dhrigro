import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { QueuesService } from '../queues/queues.service';
import { QUEUE_NAMES } from '../queues/queue.constants';
import { SocketRealtimeService } from '../realtime/socket-realtime.service';
import { REALTIME_ROOMS } from '../realtime/realtime-events';

export interface AutomationRule {
  id: string;
  name: string;
  enabled: boolean;
  trigger: string;
  description: string;
}

const DEFAULT_RULES: AutomationRule[] = [
  {
    id: 'auto_delayed',
    name: 'Mark delayed orders',
    enabled: true,
    trigger: 'cron:hourly',
    description: 'Flag orders pending >2h for ops review',
  },
  {
    id: 'auto_stock_alert',
    name: 'Low stock alerts',
    enabled: true,
    trigger: 'stock:below_threshold',
    description: 'Enqueue stock alert jobs when SKU drops below 10',
  },
  {
    id: 'auto_cancel_cod',
    name: 'Cancel abandoned COD',
    enabled: false,
    trigger: 'order:pending_timeout',
    description: 'Auto-cancel COD orders pending >24h',
  },
  {
    id: 'auto_vip_priority',
    name: 'VIP order priority',
    enabled: true,
    trigger: 'order:created',
    description: 'Boost VIP customer orders in dispatch queue',
  },
  {
    id: 'auto_assign_nearest',
    name: 'Auto-assign nearest partner',
    enabled: false,
    trigger: 'order:packed',
    description: 'Assign to nearest online partner (requires location)',
  },
];

@Injectable()
export class AutomationService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(AutomationService.name);
  private rules = [...DEFAULT_RULES];
  private interval?: ReturnType<typeof setInterval>;

  constructor(
    private prisma: PrismaService,
    private queues: QueuesService,
    private realtime: SocketRealtimeService,
  ) {}

  onModuleInit() {
    this.interval = setInterval(
      () => void this.runHourlyAutomations(),
      60 * 60 * 1000,
    );
  }

  onModuleDestroy() {
    if (this.interval) clearInterval(this.interval);
  }

  getRules(): AutomationRule[] {
    return this.rules;
  }

  updateRule(id: string, enabled: boolean): AutomationRule | null {
    const rule = this.rules.find((r) => r.id === id);
    if (!rule) return null;
    rule.enabled = enabled;
    return rule;
  }

  async runHourlyAutomations() {
    if (this.isEnabled('auto_delayed')) {
      await this.flagDelayedOrders();
    }
    if (this.isEnabled('auto_stock_alert')) {
      await this.checkLowStock();
    }
  }

  async onOrderCreated(orderId: string, userId: string) {
    if (!this.isEnabled('auto_vip_priority')) return;

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { loyaltyPoints: true },
    });
    if ((user?.loyaltyPoints ?? 0) >= 500) {
      this.logger.log(`VIP priority applied to order ${orderId}`);
    }
  }

  private isEnabled(ruleId: string): boolean {
    return this.rules.find((r) => r.id === ruleId)?.enabled ?? false;
  }

  private async flagDelayedOrders() {
    const cutoff = new Date(Date.now() - 2 * 60 * 60 * 1000);
    const delayed = await this.prisma.order.findMany({
      where: {
        status: { in: ['PENDING', 'CONFIRMED'] },
        placedAt: { lt: cutoff },
      },
      take: 50,
      select: { id: true, orderNumber: true },
    });

    for (const o of delayed) {
      await this.realtime.publish({
        type: 'order_updated',
        room: REALTIME_ROOMS.admin,
        payload: { orderId: o.id, orderNumber: o.orderNumber, delayed: true },
      });
    }
  }

  private async checkLowStock() {
    const low = await this.prisma.product.findMany({
      where: { stock: { lte: 10 }, isActive: true },
      take: 20,
      select: { id: true, name: true, stock: true },
    });

    for (const p of low) {
      await this.queues.enqueue(QUEUE_NAMES.STOCK_ALERTS, {
        type: 'stock_alert',
        data: { productId: p.id, name: p.name, stock: p.stock },
      });
      await this.realtime.publish({
        type: 'stock_low',
        room: REALTIME_ROOMS.admin,
        payload: { productId: p.id, name: p.name, stock: p.stock },
      });
    }
  }
}
