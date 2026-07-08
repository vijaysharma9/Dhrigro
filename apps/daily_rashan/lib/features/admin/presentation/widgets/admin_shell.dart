import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/admin/admin_live_ops.dart';
import '../../../../core/admin/admin_permissions.dart';
import '../../../../core/admin/admin_theme.dart';
import '../../../../core/admin/admin_theme_mode_provider.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/admin/admin_connection_indicator.dart';
import '../../../../shared/widgets/admin/admin_offline_banner.dart';
import '../../../../shared/widgets/admin/admin_global_search.dart';
import '../../../../shared/widgets/admin/admin_notifications.dart';
import '../../../../shared/widgets/admin/admin_quick_actions.dart';
import '../../../../core/admin/admin_realtime.dart';
import '../providers/admin_providers.dart';

enum AdminSection {
  dashboard,
  orders,
  users,
  products,
  categories,
  inventory,
  coupons,
  banners,
  delivery,
  reports,
  system,
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
      case AdminSection.categories:
        return 'categories';
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
      case AdminSection.system:
        return 'system';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminSection.dashboard:
        return Icons.dashboard_outlined;
      case AdminSection.orders:
        return Icons.shopping_bag_outlined;
      case AdminSection.users:
        return Icons.people_outline;
      case AdminSection.products:
        return Icons.inventory_2_outlined;
      case AdminSection.categories:
        return Icons.category_outlined;
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
      case AdminSection.system:
        return Icons.monitor_heart_outlined;
    }
  }

  IconData get selectedIcon {
    switch (this) {
      case AdminSection.dashboard:
        return Icons.dashboard;
      case AdminSection.orders:
        return Icons.shopping_bag;
      case AdminSection.users:
        return Icons.people;
      case AdminSection.products:
        return Icons.inventory_2;
      case AdminSection.categories:
        return Icons.category;
      case AdminSection.inventory:
        return Icons.warehouse;
      case AdminSection.coupons:
        return Icons.local_offer;
      case AdminSection.banners:
        return Icons.image;
      case AdminSection.delivery:
        return Icons.local_shipping;
      case AdminSection.reports:
        return Icons.analytics;
      case AdminSection.system:
        return Icons.monitor_heart;
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
      case AdminSection.categories:
        return 'Categories';
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
      case AdminSection.system:
        return 'System';
    }
  }

  String? get group {
    switch (this) {
      case AdminSection.dashboard:
        return 'Overview';
      case AdminSection.orders:
      case AdminSection.delivery:
        return 'Operations';
      case AdminSection.users:
      case AdminSection.coupons:
        return 'Customers';
      case AdminSection.products:
      case AdminSection.categories:
      case AdminSection.inventory:
      case AdminSection.banners:
        return 'Catalog';
      case AdminSection.reports:
        return 'Analytics';
      case AdminSection.system:
        return 'Platform';
    }
  }
}

class AdminShell extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  bool _sidebarCollapsed = false;

  List<AdminSection> _visibleSections(String? role) {
    return AdminSection.values
        .where((s) => AdminPermissions.canAccess(role, s.permissionKey))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final role = user?.role;
    final visible = _visibleSections(role);
    final width = MediaQuery.sizeOf(context).width;
    final useDrawer = width < 900;
    final sidebarWidth = _sidebarCollapsed ? 72.0 : 240.0;

    final dashboardAsync = ref.watch(adminDashboardProvider);
    ref.watch(adminRealtimeProvider);
    final isSyncing = ref.watch(adminSilentSyncProvider);
    final lastSync = ref.watch(adminLastSyncProvider);
    final themeMode = ref.watch(adminThemeModeProvider);
    final isDark = themeMode.valueOrNull == ThemeMode.dark;
    final notifications = dashboardAsync.valueOrNull != null
        ? notificationsFromDashboard(dashboardAsync.valueOrNull!)
        : <AdminNotificationItem>[];

    return AdminSearchShortcut(
      onSearch: () => AdminGlobalSearch.show(
        context,
        onNavigate: widget.onSectionChanged,
      ),
      child: Scaffold(
      backgroundColor: context.adminTheme.surface,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: AdminQuickActionsFab(
        onAction: widget.onSectionChanged,
        canAccess: (s) => AdminPermissions.canAccess(role, s.permissionKey),
      ),
      drawer: useDrawer
          ? _AdminDrawer(
              section: widget.section,
              visible: visible,
              onTap: widget.onSectionChanged,
              user: user,
              onLogout: _confirmLogout,
            )
          : null,
      body: Row(
        children: [
          if (!useDrawer)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: sidebarWidth,
              margin: const EdgeInsets.all(AdminSpacing.md),
              child: _AdminSideNav(
                section: widget.section,
                visible: visible,
                collapsed: _sidebarCollapsed,
                onTap: widget.onSectionChanged,
                onToggleCollapse: () =>
                    setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                user: user,
                onLogout: _confirmLogout,
              ),
            ),
          Expanded(
            child: Column(
              children: [
                _AdminTopBar(
                  section: widget.section,
                  role: role,
                  user: user,
                  lastSync: lastSync,
                  isSyncing: isSyncing,
                  isDark: isDark,
                  onToggleTheme: () => ref.read(adminThemeModeProvider.notifier).toggle(),
                  onRefresh: widget.onRefresh != null ? _handleRefresh : null,
                  onSearch: () => AdminGlobalSearch.show(
                    context,
                    onNavigate: widget.onSectionChanged,
                  ),
                  notifications: AdminNotificationsMenu(
                    items: notifications,
                    onNavigate: widget.onSectionChanged,
                  ),
                  onLogout: _confirmLogout,
                  showMenuButton: useDrawer,
                ),
                Expanded(
                  child: Column(
                    children: [
                      const AdminOfflineBanner(),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(
                            0,
                            0,
                            AdminSpacing.md,
                            AdminSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: context.adminTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(AdminRadius.lg),
                            border: Border.all(color: context.adminTheme.border),
                            boxShadow: AdminShadows.card,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: KeyedSubtree(
                              key: ValueKey(widget.section),
                              child: widget.child,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    ref.read(adminSilentSyncProvider.notifier).state = true;
    widget.onRefresh?.call();
    ref.read(adminLastSyncProvider.notifier).state = DateTime.now();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      ref.read(adminSilentSyncProvider.notifier).state = false;
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access the admin panel.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref.read(authStateProvider.notifier).logout();
    }
  }
}

String _userInitial(UserModel? user) {
  final name = user?.name?.trim();
  if (name != null && name.isNotEmpty) return name[0].toUpperCase();
  return 'A';
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.section,
    required this.role,
    required this.user,
    this.onRefresh,
    this.onSearch,
    this.lastSync,
    this.isSyncing = false,
    this.isDark = false,
    this.onToggleTheme,
    this.notifications,
    required this.onLogout,
    required this.showMenuButton,
  });

  final AdminSection section;
  final String? role;
  final UserModel? user;
  final VoidCallback? onRefresh;
  final VoidCallback? onSearch;
  final DateTime? lastSync;
  final bool isSyncing;
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final Widget? notifications;
  final VoidCallback onLogout;
  final bool showMenuButton;

  @override
  Widget build(BuildContext context) {
    final theme = context.adminTheme;
    return Container(
      height: 56,
      margin: const EdgeInsets.only(
        top: AdminSpacing.md,
        right: AdminSpacing.md,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.lg),
      decoration: BoxDecoration(
        color: theme.surfaceCard,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: theme.border),
        boxShadow: AdminShadows.card,
      ),
      child: Row(
        children: [
          if (showMenuButton)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGreen,
                  AppColors.primaryGreen.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.store, color: Colors.white, size: 16),
          ),
          const SizedBox(width: AdminSpacing.sm),
          Text(
            section.label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: theme.textPrimary,
            ),
          ),
          const Spacer(),
          const AdminConnectionIndicator(),
          const SizedBox(width: AdminSpacing.sm),
          if (onToggleTheme != null)
            IconButton(
              onPressed: onToggleTheme,
              icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 20),
              tooltip: isDark ? 'Light mode' : 'Dark mode',
              visualDensity: VisualDensity.compact,
            ),
          if (onSearch != null)
            IconButton(
              onPressed: onSearch,
              icon: const Icon(Icons.search, size: 20),
              tooltip: 'Search (⌘K)',
              visualDensity: VisualDensity.compact,
            ),
          if (onRefresh != null)
            IconButton(
              onPressed: isSyncing ? null : onRefresh,
              icon: isSyncing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryGreen.withValues(alpha: 0.8),
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Refresh',
              visualDensity: VisualDensity.compact,
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSyncing ? AdminSemanticColors.warning : AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isSyncing
                    ? 'Syncing…'
                    : lastSync != null
                        ? 'Synced ${_formatSync(lastSync!)}'
                        : 'Live',
                style: TextStyle(fontSize: 10, color: theme.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: AdminSpacing.sm),
          if (notifications != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: notifications!,
            )
          else
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 20),
              onPressed: () {},
              visualDensity: VisualDensity.compact,
            ),
          const SizedBox(width: AdminSpacing.sm),
          _EnvBadge(),
          const SizedBox(width: AdminSpacing.sm),
          PopupMenuButton<String>(
            offset: const Offset(0, 40),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                  child: Text(
                    _userInitial(user),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (MediaQuery.sizeOf(context).width > 600) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user?.name ?? 'Admin',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        role ?? 'STAFF',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AdminSemanticColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.expand_more, size: 16),
                ],
              ],
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(user?.email ?? user?.phone ?? ''),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: const Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
            onSelected: (v) {
              if (v == 'logout') onLogout();
            },
          ),
        ],
      ),
    );
  }
}

String _formatSync(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  return '${diff.inHours}h ago';
}

class _EnvBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final env = EnvConfig.environment.name.toUpperCase();
    final isProd = EnvConfig.isProduction;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isProd ? AppColors.errorRed : AppColors.primaryGreen)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AdminRadius.pill),
        border: Border.all(
          color: (isProd ? AppColors.errorRed : AppColors.primaryGreen)
              .withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        env,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: isProd ? AppColors.errorRed : AppColors.primaryGreen,
        ),
      ),
    );
  }
}

class _AdminSideNav extends StatelessWidget {
  const _AdminSideNav({
    required this.section,
    required this.visible,
    required this.collapsed,
    required this.onTap,
    required this.onToggleCollapse,
    required this.user,
    required this.onLogout,
  });

  final AdminSection section;
  final List<AdminSection> visible;
  final bool collapsed;
  final ValueChanged<AdminSection> onTap;
  final VoidCallback onToggleCollapse;
  final UserModel? user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<AdminSection>>{};
    for (final s in visible) {
      groups.putIfAbsent(s.group ?? 'Other', () => []).add(s);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyBlue,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        boxShadow: AdminShadows.elevated,
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(collapsed ? AdminSpacing.sm : AdminSpacing.lg),
            child: Row(
              children: [
                if (!collapsed) ...[
                  const Expanded(
                    child: Text(
                      'Dhrigro',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
                IconButton(
                  onPressed: onToggleCollapse,
                  icon: Icon(
                    collapsed ? Icons.menu_open : Icons.menu_open,
                    color: Colors.white70,
                    size: 20,
                  ),
                  tooltip: collapsed ? 'Expand' : 'Collapse',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? AdminSpacing.xs : AdminSpacing.sm,
              ),
              children: [
                for (final entry in groups.entries) ...[
                  if (!collapsed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ...entry.value.map((target) => _navItem(target)),
                ],
              ],
            ),
          ),
          _SidebarFooter(
            collapsed: collapsed,
            user: user,
            onLogout: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _navItem(AdminSection target) {
    final selected = section == target;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(AdminRadius.sm),
        child: InkWell(
          onTap: () => onTap(target),
          borderRadius: BorderRadius.circular(AdminRadius.sm),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? AdminSpacing.sm : AdminSpacing.md,
              vertical: AdminSpacing.sm,
            ),
            decoration: selected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(AdminRadius.sm),
                    border: Border(
                      left: BorderSide(color: AppColors.primaryGreen, width: 3),
                    ),
                  )
                : null,
            child: Row(
              children: [
                Icon(
                  selected ? target.selectedIcon : target.icon,
                  color: selected ? AppColors.primaryGreen : Colors.white70,
                  size: 20,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: AdminSpacing.md),
                  Expanded(
                    child: Text(
                      target.label,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({
    required this.collapsed,
    required this.user,
    required this.onLogout,
  });

  final bool collapsed;
  final UserModel? user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(collapsed ? AdminSpacing.sm : AdminSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: collapsed
          ? IconButton(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
              tooltip: 'Sign out',
            )
          : Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                  child: Text(
                    _userInitial(user),
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: AdminSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Admin',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.role ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, size: 18, color: Colors.white70),
                  tooltip: 'Sign out',
                ),
              ],
            ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({
    required this.section,
    required this.visible,
    required this.onTap,
    required this.user,
    required this.onLogout,
  });

  final AdminSection section;
  final List<AdminSection> visible;
  final ValueChanged<AdminSection> onTap;
  final UserModel? user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.navyBlue),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Dhrigro Ops',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.name ?? 'Admin',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: visible.map((target) {
                return ListTile(
                  leading: Icon(
                    section == target ? target.selectedIcon : target.icon,
                    color: section == target ? AppColors.primaryGreen : null,
                  ),
                  title: Text(target.label),
                  selected: section == target,
                  onTap: () {
                    Navigator.pop(context);
                    onTap(target);
                  },
                );
              }).toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}
