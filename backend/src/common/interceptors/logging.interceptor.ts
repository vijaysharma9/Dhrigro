import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import { Request, Response } from 'express';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const http = context.switchToHttp();
    const req = http.getRequest<Request & { requestId?: string }>();
    const res = http.getResponse<Response>();
    const { method, url } = req;
    const requestId = req.requestId || '-';
    const start = Date.now();

    return next.handle().pipe(
      tap({
        next: () => {
          const ms = Date.now() - start;
          const log = {
            level: 'info',
            msg: 'http_request',
            method,
            url,
            statusCode: res.statusCode,
            durationMs: ms,
            requestId,
          };
          this.logger.log(JSON.stringify(log));
          if (ms > 2000) {
            this.logger.warn(
              JSON.stringify({ ...log, level: 'warn', msg: 'slow_request' }),
            );
          }
        },
        error: (err: Error) => {
          const ms = Date.now() - start;
          this.logger.error(
            JSON.stringify({
              level: 'error',
              msg: 'http_request_failed',
              method,
              url,
              durationMs: ms,
              requestId,
              error: err.message,
            }),
          );
        },
      }),
    );
  }
}
