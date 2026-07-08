import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/admin/admin_live_ops.dart';
import '../../../../core/admin/admin_permissions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_shell.dart';
import 'admin_banners_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_coupons_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_delivery_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_system_screen.dart';
import 'admin_users_screen.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  AdminSection _section = AdminSection.dashboard;
  AdminSectionPoller? _poller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _configurePolling(_section));
  }

  @override
  void dispose() {
    _poller?.stop();
    super.dispose();
  }

  AdminSection _firstAllowedSection(String? role) {
    for (final s in AdminSection.values) {
      if (AdminPermissions.canAccess(role, s.permissionKey)) return s;
    }
    return AdminSection.dashboard;
  }

  void _configurePolling(AdminSection section) {
    _poller ??= AdminSectionPoller(ref);
    _poller!.stop();

    final interval = switch (section) {
      AdminSection.dashboard => const Duration(seconds: 20),
      AdminSection.orders => const Duration(seconds: 15),
      AdminSection.delivery => const Duration(seconds: 10),
      _ => null,
    };

    if (interval == null) return;

    _poller!.start(() {
      switch (section) {
        case AdminSection.dashboard:
          ref.invalidate(adminDashboardProvider);
        case AdminSection.orders:
          ref.invalidate(adminOrdersListProvider);
        case AdminSection.delivery:
          ref.invalidate(adminDeliveryBoardProvider);
          ref.invalidate(adminDeliveryOpsProvider);
          ref.invalidate(adminPartnersProvider);
          ref.invalidate(adminDeliverySlotsProvider);
        default:
          break;
      }
    }, interval);
  }

  void _changeSection(AdminSection s) {
    setState(() => _section = s);
    _configurePolling(s);
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authStateProvider).valueOrNull?.role;
    if (!AdminPermissions.canAccess(role, _section.permissionKey)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _changeSection(_firstAllowedSection(role));
        }
      });
    }

    Widget body;
    VoidCallback? onRefresh;

    switch (_section) {
      case AdminSection.dashboard:
        body = AdminDashboardScreen(
          embedded: true,
          onNavigate: _changeSection,
        );
        onRefresh = () => ref.invalidate(adminDashboardProvider);
      case AdminSection.orders:
        body = const AdminOrdersScreen();
        onRefresh = () => ref.invalidate(adminOrdersListProvider);
      case AdminSection.users:
        body = const AdminUsersScreen();
        onRefresh = () => ref.invalidate(adminUsersListProvider);
      case AdminSection.products:
        body = const AdminProductsScreen();
        onRefresh = () => ref.invalidate(adminProductsProvider);
      case AdminSection.categories:
        body = const AdminCategoriesScreen();
        onRefresh = () {
          ref.invalidate(adminCategoriesProvider);
          ref.invalidate(adminCategoryAnalyticsProvider);
        };
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
          ref.invalidate(adminDeliveryBoardProvider);
          ref.invalidate(adminDeliverySlotsProvider);
          ref.invalidate(adminDeliverySettingsProvider);
          ref.invalidate(adminDeliveryOpsProvider);
          ref.invalidate(adminPartnersProvider);
        };
      case AdminSection.reports:
        body = const AdminReportsScreen();
      case AdminSection.system:
        body = const AdminSystemScreen();
        onRefresh = () {
          ref.invalidate(adminSystemHealthProvider);
          ref.invalidate(adminAuditLogsProvider);
        };
    }

    return AdminShell(
      section: _section,
      onSectionChanged: _changeSection,
      onRefresh: onRefresh,
      child: body,
    );
  }
}
