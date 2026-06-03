import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/csv_download.dart';
import '../../../../shared/widgets/admin/admin_data_table.dart';
import '../../../../shared/widgets/admin/admin_search_bar.dart';
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

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Users', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  final csv = await ref
                      .read(adminRepositoryProvider)
                      .exportUsersCsv(search: query.search);
                  await downloadCsv('users.csv', csv);
                },
                icon: const Icon(Icons.download),
                label: const Text('Export'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdminSearchBar(
            hint: 'Search name, phone, email',
            onChanged: _debouncedSearch,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (res) {
                final rows = (res['data'] as List? ?? [])
                    .cast<Map<String, dynamic>>();
                final meta = res['meta'] as Map<String, dynamic>? ?? {};

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: AdminDataTable<Map<String, dynamic>>(
                          columns: [
                            AdminColumn(
                              label: 'Name',
                              flex: 2,
                              cellBuilder: (u) => Text(
                                u['name'] as String? ?? '—',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            AdminColumn(
                              label: 'Phone',
                              flex: 2,
                              cellBuilder: (u) => Text(u['phone'] as String? ?? '—'),
                            ),
                            AdminColumn(
                              label: 'Orders',
                              cellBuilder: (u) =>
                                  Text('${u['_count']?['orders'] ?? 0}'),
                            ),
                            AdminColumn(
                              label: 'Status',
                              cellBuilder: (u) {
                                final active = u['isActive'] as bool? ?? true;
                                return Chip(
                                  label: Text(active ? 'Active' : 'Blocked'),
                                  backgroundColor: active
                                      ? AppColors.primaryGreen.withValues(alpha: 0.1)
                                      : AppColors.errorRed.withValues(alpha: 0.1),
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
          ),
        ],
      ),
    );
  }
}

class _UserDetailDrawer extends ConsumerWidget {
  const _UserDetailDrawer({
    required this.userId,
    required this.onUpdated,
  });

  final String userId;
  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(adminRepositoryProvider).getUser(userId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data!;
        final stats = user['stats'] as Map<String, dynamic>? ?? {};
        final orders = user['orders'] as List? ?? [];
        final addresses = user['addresses'] as List? ?? [];
        final isActive = user['isActive'] as bool? ?? true;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          builder: (_, c) => ListView(
            controller: c,
            padding: const EdgeInsets.all(24),
            children: [
              Text(user['name'] as String? ?? 'User',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(user['phone'] as String? ?? ''),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  _miniStat('Total spend', '₹${stats['totalSpend'] ?? 0}'),
                  _miniStat('Orders', '${stats['totalOrders'] ?? 0}'),
                  _miniStat('Coupons used', '${stats['couponsUsed'] ?? 0}'),
                ],
              ),
              const Divider(height: 32),
              Text('Addresses', style: Theme.of(context).textTheme.titleMedium),
              ...addresses.map((a) {
                final addr = a as Map<String, dynamic>;
                return ListTile(
                  title: Text(addr['line1'] as String? ?? ''),
                  subtitle: Text('${addr['city']} ${addr['pincode']}'),
                );
              }),
              Text('Recent orders', style: Theme.of(context).textTheme.titleMedium),
              ...orders.map((o) {
                final order = o as Map<String, dynamic>;
                return ListTile(
                  title: Text(order['orderNumber'] as String? ?? ''),
                  trailing: Text('₹${order['totalAmount']}'),
                );
              }),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isActive ? AppColors.errorRed : AppColors.primaryGreen,
                ),
                onPressed: () async {
                  await ref
                      .read(adminRepositoryProvider)
                      .setUserActive(userId, !isActive);
                  onUpdated();
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(isActive ? 'Block user' : 'Unblock user'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _miniStat(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}
