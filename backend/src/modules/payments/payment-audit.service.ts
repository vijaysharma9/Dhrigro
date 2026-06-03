import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class PaymentAuditService {
  constructor(private prisma: PrismaService) {}

  async log(data: {
    orderId?: string;
    userId?: string;
    eventType: string;
    status?: string;
    source?: string;
    payload?: Record<string, unknown>;
  }) {
    return this.prisma.paymentAuditLog.create({
      data: {
        orderId: data.orderId,
        userId: data.userId,
        eventType: data.eventType,
        status: data.status,
        source: data.source,
        payload: data.payload as object,
      },
    });
  }

  async listForOrder(orderId: string) {
    return this.prisma.paymentAuditLog.findMany({
      where: { orderId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }
}
