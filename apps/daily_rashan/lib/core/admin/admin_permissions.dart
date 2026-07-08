/// Client-side nav visibility aligned with backend ROLE_PERMISSIONS.
class AdminPermissions {
  AdminPermissions._();

  static const allSections = [
    'dashboard',
    'orders',
    'users',
    'products',
    'categories',
    'inventory',
    'coupons',
    'banners',
    'delivery',
    'reports',
    'system',
  ];

  static List<String> sectionsForRole(String? role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return allSections;
      case 'OPERATIONS_ADMIN':
        return ['dashboard', 'orders', 'delivery', 'reports', 'system'];
      case 'INVENTORY_MANAGER':
        return [
          'dashboard',
          'products',
          'categories',
          'inventory',
          'banners',
          'reports',
        ];
      case 'CUSTOMER_SUPPORT':
        return ['dashboard', 'orders', 'users', 'coupons'];
      default:
        return [];
    }
  }

  static bool canAccess(String? role, String section) {
    return sectionsForRole(role).contains(section);
  }
}
