import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '@prisma/client';
import {
  ADMIN_ACCESS_KEY,
  AdminPermission,
  roleHasPermission,
  STAFF_ROLES,
} from '../rbac/permissions';

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<AdminPermission[]>(
      ADMIN_ACCESS_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!required?.length) {
      return true;
    }

    const { user } = context.switchToHttp().getRequest();
    if (!user?.role || !STAFF_ROLES.includes(user.role)) {
      throw new ForbiddenException('Staff access required');
    }

    const allowed = required.some((perm) =>
      roleHasPermission(user.role as UserRole, perm),
    );

    if (!allowed) {
      throw new ForbiddenException('Insufficient permissions');
    }

    return true;
  }
}
