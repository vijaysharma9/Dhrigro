import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import { Request } from 'express';
import { AuditService } from './audit.service';

@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(private audit: AuditService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (context.getType() !== 'http') return next.handle();

    const req = context.switchToHttp().getRequest<
      Request & { user?: { id: string; sub?: string }; requestId?: string }
    >();

    const method = req.method;
    if (!['POST', 'PUT', 'PATCH', 'DELETE'].includes(method)) {
      return next.handle();
    }

    const path = req.url.split('?')[0];
    if (!path.includes('/admin/')) return next.handle();

    const userId = req.user?.id ?? req.user?.sub;
    if (!userId) return next.handle();

    const resource = path.split('/').slice(-2).join('/') || 'admin';

    return next.handle().pipe(
      tap({
        next: () => {
          void this.audit.log({
            userId,
            action: `${method} ${path}`,
            resource: 'admin',
            resourceId: (req.params as Record<string, string>)?.id,
            metadata: { requestId: req.requestId },
            ipAddress: req.ip,
            userAgent: req.headers['user-agent'],
          });
        },
      }),
    );
  }
}
