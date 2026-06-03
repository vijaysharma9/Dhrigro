import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/admin/admin_permissions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_shell.dart';
import 'admin_banners_screen.dart';
import 'admin_coupons_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_delivery_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_users_screen.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  AdminSection _section = AdminSection.dashboard;

  AdminSection _firstAllowedSection(String? role) {
    for (final s in AdminSection.values) {
      if (AdminPermissions.canAccess(role, s.permissionKey)) return s;
    }
    return AdminSection.dashboard;
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authStateProvider).valueOrNull?.role;
    if (!AdminPermissions.canAccess(role, _section.permissionKey)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _section = _firstAllowedSection(role));
        }
      });
    }

    Widget body;
    VoidCallback? onRefresh;

    switch (_section) {
      case AdminSection.dashboard:
        body = const AdminDashboardScreen(embedded: true);
        onRefresh = () => ref.invalidate(adminDashboardProvider);
      case AdminSection.orders:
        body = const AdminOrdersScreen();
        onRefresh = () => ref.invalidate(adminOrdersListProvider);
      case AdminSection.users:
        body = const AdminUsersScreen();
        onRefresh = () => ref.invalidate(adminUsersListProvider);
      case AdminSection.products:
        body = const AdminProductsScreen();
      case AdminSection.inventory:
        body = const AdminInventoryScreen();
        onRefresh = () => ref.invalidate(adminInventoryListProvider);
      case AdminSection.coupons:
        body = const AdminCouponsScreen();
        onRefresh = () => ref.invalidate(adminCouponsProvider);
      case AdminSection.banners:
        body = const AdminBannersScreen();
        onRefresh = () => ref.invalidate(adminBannersProvider);
      case AdminSection.delivery:
        body = const AdminDeliveryScreen();
        onRefresh = () {
          ref.invalidate(adminDeliverySlotsProvider);
          ref.invalidate(adminDeliverySettingsProvider);
        };
      case AdminSection.reports:
        body = const AdminReportsScreen();
    }

    return AdminShell(
      section: _section,
      onSectionChanged: (s) => setState(() => _section = s),
      onRefresh: onRefresh,
      child: body,
    );
  }
}
