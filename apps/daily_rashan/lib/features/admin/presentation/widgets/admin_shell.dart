import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/admin/admin_permissions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

enum AdminSection {
  dashboard,
  orders,
  users,
  products,
  inventory,
  coupons,
  banners,
  delivery,
  reports,
}

extension AdminSectionX on AdminSection {
  String get permissionKey {
    switch (this) {
      case AdminSection.dashboard:
        return 'dashboard';
      case AdminSection.orders:
        return 'orders';
      case AdminSection.users:
        return 'users';
      case AdminSection.products:
        return 'products';
      case AdminSection.inventory:
        return 'inventory';
      case AdminSection.coupons:
        return 'coupons';
      case AdminSection.banners:
        return 'banners';
      case AdminSection.delivery:
        return 'delivery';
      case AdminSection.reports:
        return 'reports';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminSection.dashboard:
        return Icons.dashboard;
      case AdminSection.orders:
        return Icons.shopping_bag_outlined;
      case AdminSection.users:
        return Icons.people_outline;
      case AdminSection.products:
        return Icons.inventory_2_outlined;
      case AdminSection.inventory:
        return Icons.warehouse_outlined;
      case AdminSection.coupons:
        return Icons.local_offer_outlined;
      case AdminSection.banners:
        return Icons.image_outlined;
      case AdminSection.delivery:
        return Icons.local_shipping_outlined;
      case AdminSection.reports:
        return Icons.analytics_outlined;
    }
  }

  String get label {
    switch (this) {
      case AdminSection.dashboard:
        return 'Dashboard';
      case AdminSection.orders:
        return 'Orders';
      case AdminSection.users:
        return 'Users';
      case AdminSection.products:
        return 'Products';
      case AdminSection.inventory:
        return 'Inventory';
      case AdminSection.coupons:
        return 'Coupons';
      case AdminSection.banners:
        return 'Banners';
      case AdminSection.delivery:
        return 'Delivery';
      case AdminSection.reports:
        return 'Reports';
    }
  }
}

class AdminShell extends ConsumerWidget {
  const AdminShell({
    super.key,
    required this.section,
    required this.onSectionChanged,
    required this.child,
    this.onRefresh,
  });

  final AdminSection section;
  final ValueChanged<AdminSection> onSectionChanged;
  final Widget child;
  final VoidCallback? onRefresh;

  List<AdminSection> _visibleSections(String? role) {
    return AdminSection.values
        .where((s) => AdminPermissions.canAccess(role, s.permissionKey))
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authStateProvider).valueOrNull?.role;
    final visible = _visibleSections(role);
    final width = MediaQuery.sizeOf(context).width;
    final useDrawer = width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.store, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Daily Rashan Ops'),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navyBlue,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderLight, height: 1),
        ),
        actions: [
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text(
                role ?? 'STAFF',
                style: const TextStyle(fontSize: 11),
              ),
              backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
      drawer: useDrawer
          ? _AdminDrawer(
              section: section,
              visible: visible,
              onTap: onSectionChanged,
            )
          : null,
      body: Row(
        children: [
          if (!useDrawer)
            _AdminSideNav(
              section: section,
              visible: visible,
              onTap: onSectionChanged,
            ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSideNav extends StatelessWidget {
  const _AdminSideNav({
    required this.section,
    required this.visible,
    required this.onTap,
  });

  final AdminSection section;
  final List<AdminSection> visible;
  final ValueChanged<AdminSection> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.navyBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: visible.map((target) => _navItem(target)).toList(),
      ),
    );
  }

  Widget _navItem(AdminSection target) {
    final selected = section == target;
    return ListTile(
      leading: Icon(
        target.icon,
        color: selected ? AppColors.primaryGreen : Colors.white70,
      ),
      title: Text(
        target.label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: Colors.white.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () => onTap(target),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({
    required this.section,
    required this.visible,
    required this.onTap,
  });

  final AdminSection section;
  final List<AdminSection> visible;
  final ValueChanged<AdminSection> onTap;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.navyBlue),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Daily Rashan',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
          ...visible.map(
            (target) => ListTile(
              leading: Icon(target.icon),
              title: Text(target.label),
              selected: section == target,
              onTap: () {
                Navigator.pop(context);
                onTap(target);
              },
            ),
          ),
        ],
      ),
    );
  }
}
