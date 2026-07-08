import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/admin/admin_theme.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin/admin_section_header.dart';
import '../../../../shared/widgets/admin/admin_stat_card.dart';
import '../../../../shared/widgets/admin/admin_ops_widgets.dart';
import '../../../../shared/widgets/admin/admin_state_widgets.dart';
import '../providers/admin_providers.dart';

class AdminDeliveryFleetScreen extends ConsumerWidget {
  const AdminDeliveryFleetScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opsAsync = ref.watch(adminDeliveryOpsProvider);
    final partnersAsync = ref.watch(adminPartnersProvider);

    return Padding(
      padding: EdgeInsets.all(embedded ? AdminSpacing.md : AdminSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!embedded) ...[
            const AdminSectionHeader(
              title: 'Fleet & analytics',
              subtitle: 'Partner availability and delivery performance',
              icon: Icons.delivery_dining_outlined,
            ),
            const SizedBox(height: AdminSpacing.lg),
          ],
          if (!embedded)
            opsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => AdminErrorState(
              error: e,
              title: 'Could not load fleet stats',
              compact: true,
              onRetry: () => ref.invalidate(adminDeliveryOpsProvider),
            ),
            data: (ops) {
              return LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth > 800 ? 4 : 2;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: cols,
                    crossAxisSpacing: AdminSpacing.md,
                    mainAxisSpacing: AdminSpacing.md,
                    childAspectRatio: 2.2,
                    children: [
                      AdminStatCard(
                        title: 'Delivered (all time)',
                        value: '${ops['totalDelivered'] ?? 0}',
                        icon: Icons.check_circle_outline,
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
                        icon: Icons.local_shipping_outlined,
                        color: AppColors.orangeAccent,
                        live: true,
                      ),
                      AdminStatCard(
                        title: 'Avg delivery time',
                        value: '${ops['averageDeliveryMinutes'] ?? 0} min',
                        icon: Icons.timer_outlined,
                        color: AppColors.navyBlue,
                      ),
                    ],
                  );
                },
              );
            },
          ),
          if (!embedded) const SizedBox(height: AdminSpacing.lg),
          Text('Partners', style: AdminTypography.sectionTitle(context)),
          const SizedBox(height: AdminSpacing.sm),
          Expanded(
            child: partnersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AdminErrorState(
                error: e,
                title: 'Could not load partners',
                onRetry: () => ref.invalidate(adminPartnersProvider),
              ),
              data: (partners) {
                if (partners.isEmpty) {
                  return const Center(
                    child: Text(
                      'No delivery partners registered',
                      style: TextStyle(color: AdminSemanticColors.textSecondary),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: partners.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AdminSpacing.sm),
                  itemBuilder: (_, i) {
                    final p = partners[i] as Map<String, dynamic>;
                    final user = p['user'] as Map<String, dynamic>? ?? {};
                    final isOnline = p['isOnline'] as bool? ?? false;
                    final active = p['_count']?['assignments'] ?? 0;
                    return _PartnerCard(
                      name: user['name'] as String? ?? 'Partner',
                      phone: user['phone'] as String? ?? '',
                      isOnline: isOnline,
                      activeAssignments: active as int? ?? 0,
                      totalTrips: p['totalDeliveries'] as int? ?? 0,
                      vehicleType: p['vehicleType'] as String? ?? 'Bike',
                      rating: (p['rating'] as num?)?.toDouble() ?? 4.5,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({
    required this.name,
    required this.phone,
    required this.isOnline,
    required this.activeAssignments,
    required this.totalTrips,
    this.vehicleType = 'Bike',
    this.rating = 4.5,
  });

  final String name;
  final String phone;
  final bool isOnline;
  final int activeAssignments;
  final int totalTrips;
  final String vehicleType;
  final double rating;

  @override
  Widget build(BuildContext context) {
    const maxLoad = 5;
    final workload = ((activeAssignments / maxLoad) * 100).clamp(0, 100).round();
    final idle = !isOnline;

    return Material(
      color: AdminSemanticColors.surfaceCard,
      borderRadius: BorderRadius.circular(AdminRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AdminRadius.md),
        hoverColor: AppColors.primaryGreen.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AdminRadius.md),
            border: Border.all(
              color: isOnline
                  ? AppColors.primaryGreen.withValues(alpha: 0.25)
                  : AdminSemanticColors.border,
            ),
            boxShadow: AdminShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AdminSpacing.md),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: isOnline
                          ? AppColors.primaryGreen.withValues(alpha: 0.12)
                          : AdminSemanticColors.borderSubtle,
                      child: Icon(
                        Icons.delivery_dining,
                        color: isOnline ? AppColors.primaryGreen : AdminSemanticColors.textMuted,
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AdminSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AdminSemanticColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: [
                          AdminMetaChip(label: vehicleType, compact: true),
                          AdminMetaChip(
                            label: '★ ${rating.toStringAsFixed(1)}',
                            color: AppColors.orangeAccent,
                            compact: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isOnline ? AppColors.primaryGreen : AdminSemanticColors.textMuted)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AdminRadius.pill),
                      ),
                      child: Text(
                        isOnline ? 'ONLINE' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isOnline ? AppColors.primaryGreen : AdminSemanticColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$activeAssignments active · $totalTrips trips',
                      style: const TextStyle(fontSize: 11, color: AdminSemanticColors.textSecondary),
                    ),
                    Text(
                      idle ? 'Idle' : '$workload% load · ~${(totalTrips / 8).toStringAsFixed(1)}/hr',
                      style: TextStyle(
                        fontSize: 10,
                        color: workload > 80 ? AdminSemanticColors.warning : AdminSemanticColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
