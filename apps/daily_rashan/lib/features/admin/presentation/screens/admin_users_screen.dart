import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/admin/admin_api_utils.dart';
import '../../../../core/admin/admin_theme.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/csv_download.dart';
import '../../../../shared/widgets/admin/admin_data_table.dart';
import '../../../../shared/widgets/admin/admin_ops_widgets.dart';
import '../../../../shared/widgets/admin/admin_page_layout.dart';
import '../../../../shared/widgets/admin/admin_search_bar.dart';
import '../../../../shared/widgets/admin/admin_state_widgets.dart';
import '../../../../shared/widgets/admin/admin_toast.dart';
import '../../data/admin_repository.dart';
import '../providers/admin_providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  late final DebouncedSearch _debouncedSearch;

  @override
  void initState() {
    super.initState();
    _debouncedSearch = DebouncedSearch((q) {
      ref.read(adminUsersQueryProvider.notifier).update(
            (s) => s.copyWith(search: q, page: 1),
          );
    });
  }

  @override
  void dispose() {
    _debouncedSearch.dispose();
    super.dispose();
  }

  void _openUser(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailDrawer(
        userId: user['id'] as String,
        onUpdated: () => ref.invalidate(adminUsersListProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersListProvider);
    final query = ref.watch(adminUsersQueryProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return AdminPageLayout(
      title: 'Customers',
      subtitle: 'Customer intelligence and account management',
      actions: [
        OutlinedButton.icon(
          onPressed: () async {
            try {
              final csv = await ref
                  .read(adminRepositoryProvider)
                  .exportUsersCsv(search: query.search);
              await downloadCsv('users.csv', csv);
              if (mounted) AdminToast.success(context, 'Users exported');
            } catch (e) {
              if (mounted) AdminToast.errorFrom(context, e);
            }
          },
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('Export'),
        ),
      ],
      filters: AdminFiltersToolbar(
        children: [
          SizedBox(
            width: isMobile ? double.infinity : 280,
            child: AdminSearchBar(hint: 'Search name, phone, email', onChanged: _debouncedSearch),
          ),
          FilterChip(
            label: const Text('Active only'),
            selected: query.isActive == true,
            onSelected: (v) {
              ref.read(adminUsersQueryProvider.notifier).update(
                    (s) => AdminUsersQuery(
                      page: 1,
                      search: s.search,
                      isActive: v ? true : null,
                    ),
                  );
            },
          ),
        ],
      ),
      child: usersAsync.when(
        loading: () => const AdminLoadingState(message: 'Loading customers…'),
        error: (e, _) => AdminErrorState(
          error: e,
          title: 'Could not load customers',
          onRetry: () => ref.invalidate(adminUsersListProvider),
        ),
        data: (res) {
          final rows = AdminApiUtils.asMapList(res['data']);
          final meta = AdminApiUtils.asMap(res['meta'], context: 'users.meta');

          if (rows.isEmpty) {
            return const AdminEmptyState(
              title: 'No customers found',
              message: 'Try a different search term.',
              icon: Icons.people_outline,
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: AdminDataTable<Map<String, dynamic>>(
                    zebraStripes: true,
                    horizontalScroll: isMobile,
                    columns: [
                      AdminColumn(
                        label: 'Customer',
                        flex: 3,
                        cellBuilder: (u) {
                          final orders = u['_count']?['orders'] as int? ?? 0;
                          final spend = (u['totalSpend'] as num?) ?? 0;
                          final tier = CustomerTierBadge.fromSpend(spend, orders);
                          return Row(
                            children: [
                              AdminAvatar(name: u['name'] as String?, size: 34),
                              const SizedBox(width: AdminSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u['name'] as String? ?? '—',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    Text(
                                      u['phone'] as String? ?? u['email'] as String? ?? '',
                                      style: const TextStyle(fontSize: 11, color: AdminSemanticColors.textMuted),
                                    ),
                                    const SizedBox(height: 2),
                                    CustomerTierBadge(tier: tier),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      AdminColumn(
                        label: 'Spend',
                        cellBuilder: (u) => Text(
                          '₹${(u['totalSpend'] as num?)?.toStringAsFixed(0) ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      AdminColumn(
                        label: 'Orders',
                        cellBuilder: (u) => Text('${u['_count']?['orders'] ?? 0}'),
                      ),
                      AdminColumn(
                        label: 'Last order',
                        flex: 2,
                        cellBuilder: (u) {
                          final last = u['lastOrderAt'] as String?;
                          if (last == null) return const Text('—', style: TextStyle(fontSize: 11));
                          final dt = DateTime.tryParse(last);
                          return Text(
                            dt != null ? DateFormat('dd MMM yyyy').format(dt) : last,
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                      AdminColumn(
                        label: 'Health',
                        cellBuilder: (u) {
                          final orders = u['_count']?['orders'] as int? ?? 0;
                          final spend = (u['totalSpend'] as num?) ?? 0;
                          final last = u['lastOrderAt'] as String?;
                          final health = CustomerHealthBadge.compute(
                            isActive: u['isActive'] as bool? ?? true,
                            orders: orders,
                            spend: spend,
                            lastOrderAt: last != null ? DateTime.tryParse(last) : null,
                          );
                          return CustomerHealthBadge(health: health);
                        },
                      ),
                      AdminColumn(
                        label: 'Status',
                        cellBuilder: (u) {
                          final active = u['isActive'] as bool? ?? true;
                          return AdminMetaChip(
                            label: active ? 'Active' : 'Blocked',
                            color: active ? AppColors.primaryGreen : AppColors.errorRed,
                          );
                        },
                      ),
                    ],
                    rows: rows,
                    onRowTap: _openUser,
                  ),
                ),
              ),
              AdminPaginationBar(
                page: meta['page'] as int? ?? 1,
                totalPages: meta['totalPages'] as int? ?? 1,
                totalItems: meta['total'] as int?,
                onPageChanged: (p) {
                  ref.read(adminUsersQueryProvider.notifier).update(
                        (s) => s.copyWith(page: p),
                      );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UserDetailDrawer extends ConsumerWidget {
  const _UserDetailDrawer({required this.userId, required this.onUpdated});

  final String userId;
  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AdminSemanticColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AdminRadius.lg)),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: ref.read(adminRepositoryProvider).getUser(userId),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            final user = snap.data!;
            final stats = user['stats'] as Map<String, dynamic>? ?? {};
            final orders = user['orders'] as List? ?? [];
            final addresses = user['addresses'] as List? ?? [];
            final isActive = user['isActive'] as bool? ?? true;
            final ordersCount = stats['totalOrders'] as int? ?? 0;
            final spend = (stats['totalSpend'] as num?) ?? 0;
            final tier = CustomerTierBadge.fromSpend(spend, ordersCount);

            return Column(
              children: [
                const SizedBox(height: AdminSpacing.sm),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AdminSemanticColors.border,
                    borderRadius: BorderRadius.circular(AdminRadius.pill),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(AdminSpacing.lg),
                    children: [
                      Row(
                        children: [
                          AdminAvatar(name: user['name'] as String?, size: 48),
                          const SizedBox(width: AdminSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['name'] as String? ?? 'Customer',
                                    style: AdminTypography.pageTitle(context)),
                                Text(user['phone'] as String? ?? '',
                                    style: const TextStyle(color: AdminSemanticColors.textMuted)),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    CustomerTierBadge(tier: tier),
                                    CustomerHealthBadge(
                                      health: CustomerHealthBadge.compute(
                                        isActive: isActive,
                                        orders: ordersCount,
                                        spend: spend,
                                        lastOrderAt: stats['lastOrderAt'] != null
                                            ? DateTime.tryParse(stats['lastOrderAt'] as String)
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AdminSpacing.lg),
                      LayoutBuilder(
                        builder: (context, c) {
                          final cols = c.maxWidth > 500 ? 4 : 2;
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: cols,
                            crossAxisSpacing: AdminSpacing.sm,
                            mainAxisSpacing: AdminSpacing.sm,
                            childAspectRatio: 2.2,
                            children: [
                              _StatTile('Total spend', '₹${spend.toStringAsFixed(0)}'),
                              _StatTile('Orders', '$ordersCount'),
                              _StatTile('AOV', '₹${(stats['avgOrderValue'] as num?)?.toStringAsFixed(0) ?? 0}'),
                              _StatTile('Repeat %', '${(stats['repeatPurchaseRate'] as num?)?.toStringAsFixed(0) ?? 0}%'),
                            ],
                          );
                        },
                      ),
                      if (!isActive)
                        Padding(
                          padding: const EdgeInsets.only(top: AdminSpacing.md),
                          child: AdminMetaChip(
                            label: 'Account blocked',
                            color: AppColors.errorRed,
                            icon: Icons.block,
                          ),
                        ),
                      if (stats['preferredPaymentMethod'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AdminSpacing.sm),
                          child: Text(
                            'Preferred payment: ${stats['preferredPaymentMethod']}',
                            style: const TextStyle(fontSize: 12, color: AdminSemanticColors.textSecondary),
                          ),
                        ),
                      const SizedBox(height: AdminSpacing.lg),
                      AdminSectionCard(
                        title: 'Recent orders',
                        child: orders.isEmpty
                            ? const Text('No orders yet', style: TextStyle(fontSize: 12))
                            : Column(
                                children: orders.take(5).map((raw) {
                                  final o = raw as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Expanded(child: Text('#${o['orderNumber']}', style: const TextStyle(fontSize: 12))),
                                        Text('₹${o['totalAmount']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      AdminSectionCard(
                        title: 'Saved addresses',
                        child: addresses.isEmpty
                            ? const Text('No addresses', style: TextStyle(fontSize: 12))
                            : Column(
                                children: addresses.map((raw) {
                                  final a = raw as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      '${a['addressLine1'] ?? a['line1'] ?? ''}, ${a['city']} ${a['pincode']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AdminSpacing.lg),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AdminSemanticColors.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isActive ? AppColors.errorRed : AppColors.primaryGreen,
                      ),
                      onPressed: () async {
                        await ref.read(adminRepositoryProvider).setUserActive(userId, !isActive);
                        onUpdated();
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(isActive ? 'Block customer' : 'Unblock customer'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AdminSemanticColors.border),
        borderRadius: BorderRadius.circular(AdminRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          Text(label, style: const TextStyle(fontSize: 10, color: AdminSemanticColors.textMuted)),
        ],
      ),
    );
  }
}
