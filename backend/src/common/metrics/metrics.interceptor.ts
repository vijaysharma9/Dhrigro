import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import { Request, Response } from 'express';
import { MetricsService } from './metrics.service';

@Injectable()
export class MetricsInterceptor implements NestInterceptor {
  constructor(private metrics: MetricsService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (context.getType() !== 'http') return next.handle();

    const req = context.switchToHttp().getRequest<Request>();
    const res = context.switchToHttp().getResponse<Response>();
    const start = process.hrtime.bigint();
    const route = req.route?.path || req.url.split('?')[0];

    return next.handle().pipe(
      tap({
        next: () => this.record(req.method, route, res.statusCode, start),
        error: () => this.record(req.method, route, res.statusCode || 500, start),
      }),
    );
  }

  private record(method: string, route: string, status: number, start: bigint) {
    const seconds = Number(process.hrtime.bigint() - start) / 1e9;
    this.metrics.httpRequestDuration.observe(
      { method, route, status: String(status) },
      seconds,
    );
    this.metrics.httpRequestTotal.inc({
      method,
      route,
      status: String(status),
    });
  }
}
