import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/admin/admin_api_utils.dart';
import '../../../core/admin/admin_theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/admin/data/admin_repository.dart';
import '../../../features/admin/presentation/providers/admin_providers.dart';
import '../../../features/admin/presentation/widgets/admin_shell.dart';

class _QuickCommand {
  const _QuickCommand({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onRun,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onRun;
}

/// Command palette for quick admin search (⌘K / Ctrl+K).
class AdminGlobalSearch extends ConsumerStatefulWidget {
  const AdminGlobalSearch({
    super.key,
    required this.onNavigate,
  });

  final ValueChanged<AdminSection> onNavigate;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<AdminSection> onNavigate,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AdminGlobalSearch(onNavigate: onNavigate),
    );
  }

  @override
  ConsumerState<AdminGlobalSearch> createState() => _AdminGlobalSearchState();
}

class _AdminGlobalSearchState extends ConsumerState<AdminGlobalSearch> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _loading = false;
  List<_SearchResult> _results = [];
  List<_QuickCommand> _commands = [];

  List<_QuickCommand> _defaultCommands() => [
        _QuickCommand(
          title: 'Open delayed orders',
          subtitle: 'Filter orders delayed >2h',
          icon: Icons.schedule,
          onRun: () {
            ref.read(adminOrdersQueryProvider.notifier).state =
                AdminOrdersQuery.preset(OrderOpsFilter.delayed);
            widget.onNavigate(AdminSection.orders);
          },
        ),
        _QuickCommand(
          title: 'Pending assignment',
          subtitle: 'Unassigned confirmed orders',
          icon: Icons.local_shipping_outlined,
          onRun: () {
            ref.read(adminOrdersQueryProvider.notifier).state =
                AdminOrdersQuery.preset(OrderOpsFilter.unassigned);
            widget.onNavigate(AdminSection.orders);
          },
        ),
        _QuickCommand(
          title: 'Low stock items',
          subtitle: 'Inventory alerts',
          icon: Icons.warning_amber_rounded,
          onRun: () {
            ref.read(adminInventoryQueryProvider.notifier).update(
                  (s) => s.copyWith(lowStock: true, page: 1),
                );
            widget.onNavigate(AdminSection.inventory);
          },
        ),
        _QuickCommand(
          title: 'Create coupon',
          subtitle: 'Go to coupons module',
          icon: Icons.local_offer_outlined,
          onRun: () => widget.onNavigate(AdminSection.coupons),
        ),
        _QuickCommand(
          title: 'Dispatch board',
          subtitle: 'Delivery kanban view',
          icon: Icons.view_kanban_outlined,
          onRun: () => widget.onNavigate(AdminSection.delivery),
        ),
        _QuickCommand(
          title: 'Reports dashboard',
          subtitle: 'Executive analytics',
          icon: Icons.analytics_outlined,
          onRun: () => widget.onNavigate(AdminSection.reports),
        ),
      ];

  @override
  void initState() {
    super.initState();
    _commands = _defaultCommands();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    _ctrl.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onQueryChanged);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _onQueryChanged() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _commands = _defaultCommands();
      });
      return;
    }
    if (q.length < 2) {
      setState(() {
        _results = [];
        _commands = _defaultCommands()
            .where((c) => c.title.toLowerCase().contains(q.toLowerCase()))
            .toList();
      });
      return;
    }
    setState(() => _commands = []);
    setState(() => _loading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final results = await Future.wait<dynamic>([
        repo.listOrders(page: 1, limit: 5, search: q),
        repo.listUsers(page: 1, limit: 5, search: q),
        repo.getProducts(page: 1, limit: 5, search: q),
        repo.listCoupons(),
      ]);

      final orders = (results[0] as Map)['data'] as List? ?? [];
      final users = (results[1] as Map)['data'] as List? ?? [];
      final productsPage = results[2];
      final products = productsPage is PaginatedResponse
          ? productsPage.data
          : (productsPage as Map)['data'] as List? ?? [];
      final coupons = results[3] as List;

      final matchedCoupons = coupons.where((c) {
        final code = (c as Map)['code'] as String? ?? '';
        return code.toLowerCase().contains(q.toLowerCase());
      });

      if (!mounted) return;
      setState(() {
        _results = [
          ...orders.map((o) => _SearchResult(
                title: 'Order #${(o as Map)['orderNumber']}',
                subtitle: '${o['status']} · ₹${o['totalAmount']}',
                section: AdminSection.orders,
                icon: Icons.receipt_long_outlined,
              )),
          ...users.map((u) => _SearchResult(
                title: (u as Map)['name'] as String? ?? 'User',
                subtitle: u['phone'] as String? ?? u['email'] as String? ?? '',
                section: AdminSection.users,
                icon: Icons.person_outline,
              )),
          ...products.map((p) => _SearchResult(
                title: (p as Map)['name'] as String? ?? 'Product',
                subtitle: '₹${p['basePrice']} · stock ${p['stock']}',
                section: AdminSection.products,
                icon: Icons.inventory_2_outlined,
              )),
          ...matchedCoupons.map((c) => _SearchResult(
                title: (c as Map)['code'] as String? ?? 'Coupon',
                subtitle: c['description'] as String? ?? '',
                section: AdminSection.coupons,
                icon: Icons.local_offer_outlined,
              )),
        ];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(_SearchResult r) {
    Navigator.pop(context);
    widget.onNavigate(r.section);
  }

  void _runCommand(_QuickCommand cmd) {
    Navigator.pop(context);
    cmd.onRun();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              Navigator.pop(context);
              return null;
            },
          ),
        },
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 520,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AdminSemanticColors.surfaceCard,
                borderRadius: BorderRadius.circular(AdminRadius.lg),
                boxShadow: AdminShadows.elevated,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AdminSpacing.lg),
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      decoration: InputDecoration(
                        hintText: 'Search or run a command…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _loading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AdminRadius.md),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: _results.isEmpty && _commands.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(AdminSpacing.xxl),
                            child: Text(
                              _ctrl.text.length >= 2 ? 'No results' : 'Type to search or pick a command',
                              style: const TextStyle(color: AdminSemanticColors.textMuted),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: _results.isNotEmpty ? _results.length : _commands.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: AdminSemanticColors.borderSubtle),
                            itemBuilder: (_, i) {
                              if (_results.isNotEmpty) {
                                final r = _results[i];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(r.icon, size: 20, color: AppColors.primaryGreen),
                                  title: Text(r.title, style: const TextStyle(fontSize: 13)),
                                  subtitle: Text(
                                    r.subtitle,
                                    style: const TextStyle(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => _select(r),
                                );
                              }
                              final cmd = _commands[i];
                              return ListTile(
                                dense: true,
                                leading: Icon(cmd.icon, size: 20, color: AppColors.navyBlue),
                                title: Text(cmd.title, style: const TextStyle(fontSize: 13)),
                                subtitle: Text(
                                  cmd.subtitle,
                                  style: const TextStyle(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _runCommand(cmd),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AdminSpacing.sm),
                    child: Text(
                      'ESC to close · ⌘K shortcut',
                      style: const TextStyle(fontSize: 10, color: AdminSemanticColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResult {
  const _SearchResult({
    required this.title,
    required this.subtitle,
    required this.section,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final AdminSection section;
  final IconData icon;
}

/// Wrap admin shell with keyboard shortcut for global search.
class AdminSearchShortcut extends StatelessWidget {
  const AdminSearchShortcut({
    super.key,
    required this.onSearch,
    required this.child,
  });

  final VoidCallback onSearch;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): onSearch,
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): onSearch,
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
