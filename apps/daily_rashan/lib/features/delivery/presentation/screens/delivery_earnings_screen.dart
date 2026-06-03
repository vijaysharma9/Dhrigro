import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin/admin_stat_card.dart';
import '../providers/delivery_providers.dart';

class DeliveryEarningsScreen extends ConsumerWidget {
  const DeliveryEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(deliveryEarningsProvider);

    return earningsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (data) {
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(deliveryEarningsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AdminStatCard(
                title: 'Total earnings',
                value: '₹${data['totalEarnings'] ?? 0}',
                icon: Icons.currency_rupee,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 12),
              AdminStatCard(
                title: 'Deliveries completed',
                value: '${data['totalDeliveries'] ?? 0}',
                icon: Icons.check_circle,
                color: AppColors.navyBlue,
              ),
              const SizedBox(height: 12),
              AdminStatCard(
                title: 'Last 7 days',
                value: '₹${data['last7DaysEarnings'] ?? 0}',
                subtitle: '${data['last7DaysDelivered'] ?? 0} deliveries',
                icon: Icons.trending_up,
                color: AppColors.orangeAccent,
              ),
              const SizedBox(height: 24),
              Text('Recent', style: Theme.of(context).textTheme.titleMedium),
              ...(data['recentDeliveries'] as List? ?? []).map((d) {
                final item = d as Map<String, dynamic>;
                final order = item['order'] as Map<String, dynamic>?;
                return ListTile(
                  title: Text(order?['orderNumber'] as String? ?? ''),
                  trailing: Text('₹${item['earningAmount'] ?? 0}'),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
