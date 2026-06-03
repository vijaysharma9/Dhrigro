import {
  BadRequestException,
  Injectable,
  Logger,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const Razorpay = require('razorpay');

@Injectable()
export class RazorpayService implements OnModuleInit {
  private readonly logger = new Logger(RazorpayService.name);
  private client: InstanceType<typeof Razorpay> | null = null;
  private keyId: string;
  private keySecret: string;
  private webhookSecret: string;

  constructor(private configService: ConfigService) {
    this.keyId = this.configService.get<string>('razorpay.keyId') || '';
    this.keySecret = this.configService.get<string>('razorpay.keySecret') || '';
    this.webhookSecret =
      this.configService.get<string>('razorpay.webhookSecret') || '';
  }

  onModuleInit() {
    if (this.keyId && this.keySecret) {
      this.client = new Razorpay({
        key_id: this.keyId,
        key_secret: this.keySecret,
      });
      this.logger.log('Razorpay client initialized');
    } else {
      this.logger.warn(
        'Razorpay keys not configured — online payments disabled',
      );
    }
  }

  isConfigured(): boolean {
    return !!this.client;
  }

  getKeyId(): string {
    return this.keyId;
  }

  async createOrder(amountInRupees: number, receipt: string, notes?: Record<string, string>) {
    if (!this.client) {
      throw new BadRequestException('Razorpay is not configured');
    }

    const amountPaise = Math.round(amountInRupees * 100);
    if (amountPaise < 100) {
      throw new BadRequestException('Minimum payment amount is ₹1');
    }

    const razorpayOrder = await this.client.orders.create({
      amount: amountPaise,
      currency: 'INR',
      receipt,
      notes: notes ?? {},
    });

    return razorpayOrder;
  }

  verifyPaymentSignature(
    razorpayOrderId: string,
    razorpayPaymentId: string,
    razorpaySignature: string,
  ): boolean {
    if (!this.keySecret) return false;

    const payload = `${razorpayOrderId}|${razorpayPaymentId}`;
    const expected = crypto
      .createHmac('sha256', this.keySecret)
      .update(payload)
      .digest('hex');

    return expected === razorpaySignature;
  }

  verifyWebhookSignature(rawBody: string | Buffer, signature: string): boolean {
    if (!this.webhookSecret) {
      this.logger.warn('Webhook secret not set — skipping verification');
      return process.env.NODE_ENV === 'development';
    }

    const body =
      typeof rawBody === 'string' ? rawBody : rawBody.toString('utf8');
    const expected = crypto
      .createHmac('sha256', this.webhookSecret)
      .update(body)
      .digest('hex');

    return expected === signature;
  }
}
