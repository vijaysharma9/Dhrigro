import { SetMetadata } from '@nestjs/common';
import { ADMIN_ACCESS_KEY, AdminPermission } from '../rbac/permissions';

export const AdminAccess = (...permissions: AdminPermission[]) =>
  SetMetadata(ADMIN_ACCESS_KEY, permissions);
