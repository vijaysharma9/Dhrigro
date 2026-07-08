import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import compression from 'compression';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/http-exception.filter';
import { MonitoringService } from './common/monitoring/monitoring.service';
import { validateEnv } from './config/env.validation';

async function bootstrap() {
  validateEnv();

  const app = await NestFactory.create(AppModule, {
    rawBody: true,
    logger: ['error', 'warn', 'log'],
  });
  const configService = app.get(ConfigService);
  const monitoring = app.get(MonitoringService);
  registerProcessHandlers(monitoring);
  const logger = new Logger('Bootstrap');
  const nodeEnv = configService.get<string>('nodeEnv');
  const isProduction = configService.get<boolean>('isProduction');

  if (isProduction) {
    const expressApp = app.getHttpAdapter().getInstance();
    expressApp.set('trust proxy', 1);
  }

  app.use(helmet());
  app.use(compression());
  app.enableCors({
    origin: configService.get<string[]>('corsOrigins'),
    credentials: true,
  });

  const apiPrefix = configService.get<string>('apiPrefix') || 'api/v1';
  app.setGlobalPrefix(apiPrefix, {
    exclude: ['health', 'health/(.*)', 'metrics'],
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  app.useGlobalFilters(new AllExceptionsFilter(configService, monitoring));

  if (configService.get<boolean>('swagger.enabled')) {
    const swaggerConfig = new DocumentBuilder()
      .setTitle('Dhrigro API')
      .setDescription('Grocery delivery platform REST API')
      .setVersion(configService.get<string>('app.version') || '1.0')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup('docs', app, document);
  }

  app.enableShutdownHooks();

  const port = configService.get<number>('port') || 3000;
  await app.listen(port, '0.0.0.0');

  const appUrl = configService.get<string>('app.apiUrl');
  logger.log(`API [${nodeEnv}] listening on port ${port}`);
  if (appUrl) {
    logger.log(`Public API URL: ${appUrl}`);
  }
  logger.log(`Health http://0.0.0.0:${port}/health`);
  if (configService.get<boolean>('swagger.enabled')) {
    logger.log(`Swagger http://0.0.0.0:${port}/docs`);
  }
}

function registerProcessHandlers(monitoring: MonitoringService) {
  const logger = new Logger('Process');

  process.on('unhandledRejection', (reason) => {
    logger.error(`Unhandled rejection: ${String(reason)}`);
    monitoring.captureException(reason);
  });

  process.on('uncaughtException', (error) => {
    logger.error(`Uncaught exception: ${error.message}`, error.stack);
    monitoring.captureException(error);
  });
}

bootstrap().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('Fatal bootstrap error', error);
  process.exit(1);
});
