import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Request, Response } from 'express';
import { MonitoringService } from '../monitoring/monitoring.service';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  constructor(
    private readonly config: ConfigService,
    private readonly monitoring: MonitoringService,
  ) {}

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: string | string[] = 'Internal server error';
    let errors: unknown = undefined;
    let code: string | undefined;

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();
      if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
        const res = exceptionResponse as Record<string, unknown>;
        message = (res.message as string | string[]) || exception.message;
        errors = res.errors;
        code = res.code as string | undefined;
      } else {
        message = exceptionResponse as string;
      }
    } else if (exception instanceof Error) {
      this.logger.error(exception.message, exception.stack);
      this.monitoring.captureException(exception, {
        type: 'http_exception',
      });
      message = this.config.get<boolean>('isProduction')
        ? 'Internal server error'
        : exception.message;
    } else {
      this.monitoring.captureException(exception);
    }

    const req = ctx.getRequest<Request & { requestId?: string }>();

    response.status(status).json({
      success: false,
      statusCode: status,
      code: code ?? (status >= 500 ? 'INTERNAL_ERROR' : undefined),
      message,
      errors,
      requestId: req.requestId,
      timestamp: new Date().toISOString(),
    });
  }
}
