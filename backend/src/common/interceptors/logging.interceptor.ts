import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import { Request } from 'express';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context.switchToHttp().getRequest<Request & { requestId?: string }>();
    const { method, url } = req;
    const requestId = req.requestId || '-';
    const start = Date.now();

    return next.handle().pipe(
      tap({
        next: () => {
          const ms = Date.now() - start;
          this.logger.log(`${method} ${url} ${ms}ms [${requestId}]`);
        },
        error: (err: Error) => {
          const ms = Date.now() - start;
          this.logger.error(
            `${method} ${url} ${ms}ms [${requestId}] ${err.message}`,
          );
        },
      }),
    );
  }
}
