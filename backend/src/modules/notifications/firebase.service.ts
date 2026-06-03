import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseService.name);
  private initialized = false;

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    const projectId = this.configService.get<string>('firebase.projectId');
    const clientEmail = this.configService.get<string>('firebase.clientEmail');
    let privateKey = this.configService.get<string>('firebase.privateKey');

    if (!projectId || !clientEmail || !privateKey) {
      this.logger.warn('Firebase not configured — push notifications disabled');
      return;
    }

    privateKey = privateKey.replace(/\\n/g, '\n');

    try {
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey,
          }),
        });
      }
      this.initialized = true;
      this.logger.log('Firebase Admin SDK initialized');
    } catch (error) {
      this.logger.error('Firebase initialization failed', error);
    }
  }

  isReady(): boolean {
    return this.initialized;
  }

  async sendToDevice(
    fcmToken: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<boolean> {
    if (!this.initialized) {
      this.logger.debug(`FCM skipped (not configured): ${title}`);
      return false;
    }

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: { title, body },
        data: data ?? {},
        android: {
          priority: 'high',
          notification: {
            channelId: 'daily_rashan_orders',
            color: '#1FA54A',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      });
      return true;
    } catch (error) {
      this.logger.error(`FCM send failed for token ${fcmToken.slice(0, 8)}...`, error);
      return false;
    }
  }

  async sendToMany(
    tokens: string[],
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<{ success: number; failure: number }> {
    if (!this.initialized || !tokens.length) {
      return { success: 0, failure: tokens.length };
    }

    const batchSize = 500;
    let success = 0;
    let failure = 0;

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);
      try {
        const response = await admin.messaging().sendEachForMulticast({
          tokens: batch,
          notification: { title, body },
          data: data ?? {},
        });
        success += response.successCount;
        failure += response.failureCount;
      } catch (error) {
        this.logger.error('FCM multicast failed', error);
        failure += batch.length;
      }
    }

    return { success, failure };
  }
}
