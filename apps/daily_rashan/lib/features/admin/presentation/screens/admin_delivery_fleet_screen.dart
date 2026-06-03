import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin/admin_stat_card.dart';
import '../../data/admin_repository.dart';

final adminDeliveryOpsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).deliveryOperationsAnalytics();
});

final adminPartnersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).listDeliveryPartners();
});

class AdminDeliveryFleetScreen extends ConsumerWidget {
  const AdminDeliveryFleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opsAsync = ref.watch(adminDeliveryOpsProvider);
    final partnersAsync = ref.watch(adminPartnersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fleet & analytics', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        opsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
          data: (ops) {
            return LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth > 800 ? 4 : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: cols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    AdminStatCard(
                      title: 'Delivered (all time)',
                      value: '${ops['totalDelivered'] ?? 0}',
                      icon: Icons.check_circle,
                      color: AppColors.primaryGreen,
                    ),
                    AdminStatCard(
                      title: 'Failed',
                      value: '${ops['totalFailed'] ?? 0}',
                      icon: Icons.error_outline,
                      color: AppColors.errorRed,
                    ),
                    AdminStatCard(
                      title: 'Active assignments',
                      value: '${ops['activeAssignments'] ?? 0}',
                      icon: Icons.local_shipping,
                      color: AppColors.orangeAccent,
                    ),
                    AdminStatCard(
                      title: 'Avg delivery time',
                      value: '${ops['averageDeliveryMinutes'] ?? 0} min',
                      icon: Icons.timer,
                      color: AppColors.navyBlue,
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Online partners', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: partnersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (partners) => ListView.builder(
              itemCount: partners.length,
              itemBuilder: (_, i) {
                final p = partners[i] as Map<String, dynamic>;
                final user = p['user'] as Map<String, dynamic>? ?? {};
                final active = p['_count']?['assignments'] ?? 0;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (p['isOnline'] as bool? ?? false)
                          ? AppColors.primaryGreen.withValues(alpha: 0.2)
                          : Colors.grey.shade200,
                      child: Icon(
                        Icons.delivery_dining,
                        color: (p['isOnline'] as bool? ?? false)
                            ? AppColors.primaryGreen
                            : AppColors.textGrey,
                      ),
                    ),
                    title: Text(user['name'] as String? ?? 'Partner'),
                    subtitle: Text(
                      '${user['phone']} · ${p['isOnline'] == true ? 'Online' : 'Offline'} · $active active',
                    ),
                    trailing: Text('${p['totalDeliveries'] ?? 0} trips'),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
