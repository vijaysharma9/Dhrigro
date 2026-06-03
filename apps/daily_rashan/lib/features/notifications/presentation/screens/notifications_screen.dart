import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';

final notificationsListProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/notifications');
  return res.data as Map<String, dynamic>;
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
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
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final items = (data['data'] as List?) ?? [];
          final unread = data['unreadCount'] as int? ?? 0;

          if (items.isEmpty) {
            return const _EmptyNotifications();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (unread > 0)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '$unread unread',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final n = items[i] as Map<String, dynamic>;
                    final isRead = n['isRead'] as bool? ?? false;
                    final createdAt = DateTime.tryParse(
                      n['createdAt'] as String? ?? '',
                    );
                    final orderId = (n['data'] as Map?)?['orderId'] as String?;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      color: isRead ? Colors.white : AppColors.primaryGreen.withValues(alpha: 0.05),
                      child: ListTile(
                        onTap: () async {
                          if (!isRead) {
                            final dio = ref.read(dioProvider);
                            await dio.patch('/notifications/${n['id']}/read');
                            ref.invalidate(notificationsListProvider);
                          }
                          if (orderId != null && context.mounted) {
                            context.push('/orders/$orderId');
                          }
                        },
                        leading: Icon(
                          _iconForType(n['type'] as String?),
                          color: AppColors.primaryGreen,
                        ),
                        title: Text(
                          n['title'] as String? ?? '',
                          style: TextStyle(
                            fontWeight:
                                isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n['body'] as String? ?? ''),
                            if (createdAt != null)
                              Text(
                                DateFormat('dd MMM, hh:mm a').format(createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textGrey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
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

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Order updates and offers will appear here',
            style: TextStyle(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
