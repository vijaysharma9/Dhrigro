import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import compression from 'compression';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/http-exception.filter';
import { validateEnv } from './config/env.validation';

async function bootstrap() {
  validateEnv();

  const app = await NestFactory.create(AppModule, { rawBody: true });
  const configService = app.get(ConfigService);
  const logger = new Logger('Bootstrap');
  const nodeEnv = configService.get<string>('nodeEnv');

  app.use(helmet());
  app.use(compression());
  app.enableCors({
    origin: configService.get<string[]>('corsOrigins'),
    credentials: true,
  });

  const apiPrefix = configService.get<string>('apiPrefix') || 'api/v1';
  app.setGlobalPrefix(apiPrefix, {
    exclude: ['health', 'health/(.*)'],
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  app.useGlobalFilters(new AllExceptionsFilter());

  if (nodeEnv !== 'production') {
    const swaggerConfig = new DocumentBuilder()
      .setTitle('Daily Rashan API')
      .setDescription('Grocery delivery platform REST API')
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup('docs', app, document);
  }

  const port = configService.get<number>('port') || 3000;
  await app.listen(port);
  logger.log(`API [${nodeEnv}] http://localhost:${port}/${apiPrefix}`);
  logger.log(`Health http://localhost:${port}/health`);
  if (nodeEnv !== 'production') {
    logger.log(`Swagger http://localhost:${port}/docs`);
  }
}

bootstrap();
