import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

final notificationsListProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/notifications');
  return res.data as Map<String, dynamic>;
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              await dio.patch('/notifications/read-all');
              ref.invalidate(notificationsListProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                _FilterChip(
                  label: 'Orders',
                  selected: _filter == 'orders',
                  onTap: () => setState(() => _filter = 'orders'),
                ),
                _FilterChip(
                  label: 'Offers',
                  selected: _filter == 'offers',
                  onTap: () => setState(() => _filter = 'offers'),
                ),
                _FilterChip(
                  label: 'Account',
                  selected: _filter == 'account',
                  onTap: () => setState(() => _filter = 'account'),
                ),
              ],
            ),
          ),
          Expanded(
            child: notificationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyStateWidget(
                icon: Icons.notifications_none,
                title: 'Could not load notifications',
                subtitle: 'Check your connection and try again',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(notificationsListProvider),
              ),
              data: (data) {
                final items = ((data['data'] as List?) ?? [])
                    .cast<Map<String, dynamic>>()
                    .where(_matchesFilter)
                    .toList();
                final unread = data['unreadCount'] as int? ?? 0;

                if (items.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.notifications_none,
                    title: 'No notifications',
                    subtitle: 'Order updates and offers will appear here',
                  );
                }

                final grouped = _groupByDate(items);

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    if (unread > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unread unread notification${unread == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ...grouped.entries.expand((entry) {
                      return [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyBlue,
                            ),
                          ),
                        ),
                        ...entry.value.map((n) => _NotificationTile(notification: n)),
                      ];
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesFilter(Map<String, dynamic> n) {
    final type = (n['type'] as String? ?? '').toUpperCase();
    switch (_filter) {
      case 'orders':
        return type == 'ORDER';
      case 'offers':
        return type == 'PROMOTION' || type == 'OFFER';
      case 'account':
        return type == 'SYSTEM';
      default:
        return true;
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> items,
  ) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final n in items) {
      final createdAt = DateTime.tryParse(n['createdAt'] as String? ?? '');
      final key = createdAt == null
          ? 'Earlier'
          : _dateLabel(createdAt);
      map.putIfAbsent(key, () => []).add(n);
    }
    return map;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('dd MMM yyyy').format(dt);
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final Map<String, dynamic> notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = notification['isRead'] as bool? ?? false;
    final createdAt = DateTime.tryParse(notification['createdAt'] as String? ?? '');
    final orderId = (notification['data'] as Map?)?['orderId'] as String?;
    final type = notification['type'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : AppColors.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead ? AppColors.borderLight : AppColors.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        onTap: () async {
          if (!isRead) {
            final dio = ref.read(dioProvider);
            await dio.patch('/notifications/${notification['id']}/read');
            ref.invalidate(notificationsListProvider);
          }
          if (orderId != null && context.mounted) {
            context.push('/orders/$orderId');
          }
        },
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
          child: Icon(_iconForType(type), color: AppColors.primaryGreen, size: 20),
        ),
        title: Text(
          notification['title'] as String? ?? '',
          style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['body'] as String? ?? ''),
            if (createdAt != null)
              Text(
                DateFormat('hh:mm a').format(createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
          ],
        ),
        trailing: isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'ORDER':
        return Icons.receipt_long;
      case 'PROMOTION':
      case 'OFFER':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryGreen.withValues(alpha: 0.15),
      ),
    );
  }
}
