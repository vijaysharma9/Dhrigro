import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/admin/admin_theme.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin/admin_page_layout.dart';
import '../../../../shared/widgets/admin/admin_state_widgets.dart';
import '../../../../shared/widgets/admin/admin_stat_card.dart';
import '../../data/admin_repository.dart';

final adminSystemHealthProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).getSystemHealth();
});

final adminAuditLogsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).getAuditLogs();
});

final adminAutomationRulesProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).getAutomationRules();
});

final adminBiMetricsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).getBiMetrics();
});

class AdminSystemScreen extends ConsumerWidget {
  const AdminSystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AdminSpacing.lg, AdminSpacing.lg, AdminSpacing.lg, 0),
            child: Text('System', style: AdminTypography.pageTitle(context)),
          ),
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Health'),
              Tab(text: 'Audit trail'),
              Tab(text: 'Automation'),
              Tab(text: 'Business intel'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _HealthTab(),
                _AuditTab(),
                _AutomationTab(),
                _BiTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(adminSystemHealthProvider);
    return healthAsync.when(
      loading: () => const AdminLoadingState(message: 'Loading system health…'),
      error: (e, _) => AdminErrorState(
        error: e,
        title: 'Could not load system health',
        onRetry: () => ref.invalidate(adminSystemHealthProvider),
      ),
      data: (h) {
        final api = h['api'] as Map? ?? {};
        final db = h['database'] as Map? ?? {};
        final redis = h['redis'] as Map? ?? {};
        final ws = h['websocket'] as Map? ?? {};
        final queues = h['queues'] as Map? ?? {};
        final ops = h['ops'] as Map? ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2,
                crossAxisSpacing: AdminSpacing.sm,
                mainAxisSpacing: AdminSpacing.sm,
                childAspectRatio: 2.4,
                children: [
                  AdminStatCard(
                    title: 'API latency',
                    value: '${api['latencyMs'] ?? '—'}ms',
                    icon: Icons.speed,
                    color: _statusColor(api['status'] as String?),
                    compact: true,
                  ),
                  AdminStatCard(
                    title: 'Database',
                    value: '${db['status'] ?? '—'}',
                    icon: Icons.storage_outlined,
                    color: _statusColor(db['status'] as String?),
                    compact: true,
                  ),
                  AdminStatCard(
                    title: 'Redis',
                    value: '${redis['status'] ?? '—'}',
                    icon: Icons.memory_outlined,
                    color: _statusColor(redis['status'] as String?),
                    compact: true,
                  ),
                  AdminStatCard(
                    title: 'WebSocket',
                    value: '${ws['connections'] ?? 0} conn',
                    icon: Icons.hub_outlined,
                    color: (ws['enabled'] as bool? ?? false) ? AppColors.primaryGreen : AdminSemanticColors.textMuted,
                    compact: true,
                    live: ws['enabled'] as bool? ?? false,
                  ),
                  AdminStatCard(
                    title: 'Queue depth',
                    value: '${queues['depth'] ?? 0}',
                    icon: Icons.queue_outlined,
                    color: AppColors.navyBlue,
                    compact: true,
                  ),
                  AdminStatCard(
                    title: 'Failed jobs',
                    value: '${queues['failedJobs'] ?? 0}',
                    icon: Icons.error_outline,
                    color: AppColors.errorRed,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: AdminSpacing.lg),
              Text('Operations today', style: AdminTypography.sectionTitle(context)),
              const SizedBox(height: AdminSpacing.sm),
              Wrap(
                spacing: AdminSpacing.md,
                children: [
                  _OpsChip('Payment failures', '${ops['paymentFailuresToday'] ?? 0}'),
                  _OpsChip('Pending orders', '${ops['pendingOrders'] ?? 0}'),
                  _OpsChip('Active partners', '${ops['activePartners'] ?? 0}'),
                ],
              ),
              const SizedBox(height: AdminSpacing.lg),
              if (queues['stats'] is List) ...[
                Text('Queue breakdown', style: AdminTypography.sectionTitle(context)),
                const SizedBox(height: AdminSpacing.sm),
                ...(queues['stats'] as List).map((q) {
                  final m = q as Map;
                  return ListTile(
                    dense: true,
                    title: Text(m['name'] as String? ?? '', style: const TextStyle(fontSize: 12)),
                    trailing: Text(
                      'wait ${m['waiting']} · fail ${m['failed']}',
                      style: const TextStyle(fontSize: 11, color: AdminSemanticColors.textMuted),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String? status) {
    return switch (status) {
      'ok' => AppColors.primaryGreen,
      'degraded' => AdminSemanticColors.warning,
      'error' => AppColors.errorRed,
      _ => AdminSemanticColors.textMuted,
    };
  }
}

class _OpsChip extends StatelessWidget {
  const _OpsChip(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value', style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _AuditTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(adminAuditLogsProvider);
    return auditAsync.when(
      loading: () => const AdminLoadingState(message: 'Loading audit trail…'),
      error: (e, _) => AdminErrorState(
        error: e,
        title: 'Could not load audit logs',
        onRetry: () => ref.invalidate(adminAuditLogsProvider),
      ),
      data: (res) {
        final rows = (res['data'] as List? ?? []);
        if (rows.isEmpty) {
          return const AdminEmptyState(
            title: 'No audit entries',
            message: 'Admin mutations will appear here.',
            icon: Icons.history,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final log = rows[i] as Map;
            final user = log['user'] as Map? ?? {};
            return ListTile(
              dense: true,
              leading: const Icon(Icons.admin_panel_settings_outlined, size: 18),
              title: Text(log['action'] as String? ?? '', style: const TextStyle(fontSize: 12)),
              subtitle: Text(
                '${user['name'] ?? 'Admin'} · ${log['createdAt']}',
                style: const TextStyle(fontSize: 10),
              ),
            );
          },
        );
      },
    );
  }
}

class _AutomationTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AutomationTab> createState() => _AutomationTabState();
}

class _AutomationTabState extends ConsumerState<_AutomationTab> {
  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(adminAutomationRulesProvider);
    return rulesAsync.when(
      loading: () => const AdminLoadingState(message: 'Loading automation rules…'),
      error: (e, _) => AdminErrorState(
        error: e,
        title: 'Could not load rules',
        onRetry: () => ref.invalidate(adminAutomationRulesProvider),
      ),
      data: (rules) => ListView.separated(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        itemCount: rules.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = rules[i] as Map;
          final id = r['id'] as String;
          final enabled = r['enabled'] as bool? ?? false;
          return SwitchListTile(
            title: Text(r['name'] as String? ?? '', style: const TextStyle(fontSize: 13)),
            subtitle: Text(r['description'] as String? ?? '', style: const TextStyle(fontSize: 11)),
            value: enabled,
            onChanged: (v) async {
              await ref.read(adminRepositoryProvider).updateAutomationRule(id, v);
              ref.invalidate(adminAutomationRulesProvider);
            },
          );
        },
      ),
    );
  }
}

class _BiTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biAsync = ref.watch(adminBiMetricsProvider);
    return biAsync.when(
      loading: () => const AdminLoadingState(message: 'Loading BI metrics…'),
      error: (e, _) => AdminErrorState(
        error: e,
        title: 'Could not load BI data',
        onRetry: () => ref.invalidate(adminBiMetricsProvider),
      ),
      data: (bi) {
        final insights = (bi['insights'] as List? ?? []).cast<String>();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: AdminSpacing.sm,
                mainAxisSpacing: AdminSpacing.sm,
                children: [
                  AdminStatCard(
                    title: 'Repeat rate',
                    value: '${bi['repeatPurchaseRate'] ?? 0}%',
                    icon: Icons.repeat,
                    color: AppColors.primaryGreen,
                    compact: true,
                  ),
                  AdminStatCard(
                    title: 'Avg CLV',
                    value: '₹${bi['avgCustomerLifetimeValue'] ?? 0}',
                    icon: Icons.person_outline,
                    color: AppColors.navyBlue,
                    compact: true,
                  ),
                  AdminStatCard(
                    title: 'Unique customers',
                    value: '${bi['uniqueCustomers'] ?? 0}',
                    icon: Icons.groups_outlined,
                    color: AppColors.orangeAccent,
                    compact: true,
                  ),
                  AdminStatCard(
                    title: 'Avg order',
                    value: '₹${bi['avgOrderValue'] ?? 0}',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.navyBlue,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: AdminSpacing.lg),
              Text('Insights', style: AdminTypography.sectionTitle(context)),
              ...insights.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: AppColors.primaryGreen)),
                      Expanded(child: Text(s, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
