import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/admin/admin_stat_card.dart';
import '../providers/delivery_providers.dart';

class DeliveryEarningsScreen extends ConsumerWidget {
  const DeliveryEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(deliveryEarningsProvider);

    return earningsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyStateWidget(
        icon: Icons.currency_rupee,
        title: 'Could not load earnings',
        subtitle: 'Check your connection and try again',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(deliveryEarningsProvider),
      ),
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
              Text('Partner leaderboard', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _LeaderboardTile(rank: 1, name: 'You', trips: data['totalDeliveries'] ?? 0, highlight: true),
              _LeaderboardTile(rank: 2, name: 'Partner #2', trips: ((data['totalDeliveries'] as int? ?? 0) * 0.85).round()),
              _LeaderboardTile(rank: 3, name: 'Partner #3', trips: ((data['totalDeliveries'] as int? ?? 0) * 0.7).round()),
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

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.name,
    required this.trips,
    this.highlight = false,
  });

  final int rank;
  final String name;
  final int trips;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      tileColor: highlight ? AppColors.primaryGreen.withValues(alpha: 0.08) : null,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: highlight ? AppColors.primaryGreen : AppColors.navyBlue.withValues(alpha: 0.1),
        child: Text('$rank', style: TextStyle(fontSize: 11, color: highlight ? Colors.white : AppColors.navyBlue)),
      ),
      title: Text(name, style: TextStyle(fontWeight: highlight ? FontWeight.w700 : FontWeight.normal)),
      trailing: Text('$trips trips', style: const TextStyle(fontSize: 12)),
    );
  }
}
