import { UserRole } from '@prisma/client';

export const ADMIN_ACCESS_KEY = 'adminAccess';

/** All staff roles that can access /admin routes */
export const STAFF_ROLES: UserRole[] = [
  UserRole.SUPER_ADMIN,
  UserRole.OPERATIONS_ADMIN,
  UserRole.INVENTORY_MANAGER,
  UserRole.CUSTOMER_SUPPORT,
];

export type AdminPermission =
  | 'dashboard'
  | 'orders'
  | 'users'
  | 'products'
  | 'inventory'
  | 'coupons'
  | 'banners'
  | 'delivery'
  | 'reports'
  | 'system';

export const ROLE_PERMISSIONS: Record<UserRole, AdminPermission[] | '*'> = {
  [UserRole.SUPER_ADMIN]: '*',
  [UserRole.OPERATIONS_ADMIN]: [
    'dashboard',
    'orders',
    'delivery',
    'reports',
    'system',
  ],
  [UserRole.INVENTORY_MANAGER]: [
    'dashboard',
    'products',
    'inventory',
    'banners',
    'reports',
  ],
  [UserRole.CUSTOMER_SUPPORT]: [
    'dashboard',
    'orders',
    'users',
    'coupons',
  ],
  [UserRole.DELIVERY_PARTNER]: [],
  [UserRole.CUSTOMER]: [],
};

export const DELIVERY_PARTNER_ROLE = UserRole.DELIVERY_PARTNER;

export function roleHasPermission(
  role: UserRole,
  permission: AdminPermission,
): boolean {
  const perms = ROLE_PERMISSIONS[role];
  if (perms === '*') return true;
  return Array.isArray(perms) && perms.includes(permission);
}
