import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class MonitoringService implements OnModuleInit {
  private readonly logger = new Logger(MonitoringService.name);
  private sentryEnabled = false;

  constructor(private readonly config: ConfigService) {}

  onModuleInit() {
    const dsn = this.config.get<string>('sentry.dsn');
    if (!dsn) {
      this.logger.log('Sentry disabled (SENTRY_DSN not set)');
      return;
    }

    try {
      // Optional dependency — only loaded when DSN is configured.
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const Sentry = require('@sentry/node');
      Sentry.init({
        dsn,
        environment: this.config.get<string>('nodeEnv'),
        release: this.config.get<string>('app.version'),
        tracesSampleRate: 0.1,
      });
      this.sentryEnabled = true;
      this.logger.log('Sentry initialized');
    } catch {
      this.logger.warn(
        'SENTRY_DSN is set but @sentry/node is not installed — run npm install @sentry/node',
      );
    }
  }

  captureException(error: unknown, context?: Record<string, unknown>) {
    if (!this.sentryEnabled) return;
    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const Sentry = require('@sentry/node');
      Sentry.captureException(error, { extra: context });
    } catch {
      // ignore
    }
  }
}
