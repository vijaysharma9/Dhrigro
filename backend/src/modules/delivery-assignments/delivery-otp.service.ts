import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

const OTP_TTL_MINUTES = 15;

@Injectable()
export class DeliveryOtpService {
  constructor(private prisma: PrismaService) {}

  generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  async setOrderOtp(orderId: string): Promise<string> {
    const otp = this.generateOtp();
    const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000);

    await this.prisma.order.update({
      where: { id: orderId },
      data: {
        deliveryOtp: otp,
        deliveryOtpExpiresAt: expiresAt,
        deliveryOtpSentAt: new Date(),
      },
    });

    return otp;
  }

  async verifyOrderOtp(orderId: string, otp: string): Promise<boolean> {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: {
        deliveryOtp: true,
        deliveryOtpExpiresAt: true,
      },
    });

    if (!order?.deliveryOtp || !order.deliveryOtpExpiresAt) {
      return false;
    }

    if (new Date() > order.deliveryOtpExpiresAt) {
      return false;
    }

    return order.deliveryOtp === otp.trim();
  }

  async clearOrderOtp(orderId: string) {
    await this.prisma.order.update({
      where: { id: orderId },
      data: {
        deliveryOtp: null,
        deliveryOtpExpiresAt: null,
      },
    });
  }
}
