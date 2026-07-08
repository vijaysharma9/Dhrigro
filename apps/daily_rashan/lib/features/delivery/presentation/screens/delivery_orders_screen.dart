import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../providers/delivery_providers.dart';
import 'delivery_order_detail_screen.dart';

class DeliveryOrdersScreen extends ConsumerWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedAsync = ref.watch(deliveryAssignedProvider);

    return assignedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyStateWidget(
        icon: Icons.local_shipping_outlined,
        title: 'Could not load orders',
        subtitle: 'Check your connection and try again',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(deliveryAssignedProvider),
      ),
      data: (res) {
        final list = (res['data'] as List? ?? []).cast<Map<String, dynamic>>();
        if (list.isEmpty) {
          return const Center(
            child: Text('No assigned orders', style: TextStyle(color: AppColors.textGrey)),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(deliveryAssignedProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final assignment = list[i];
              final order = assignment['order'] as Map<String, dynamic>? ?? {};
              final user = order['user'] as Map<String, dynamic>?;
              final status = assignment['status'] as String? ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(order['orderNumber'] as String? ?? ''),
                  subtitle: Text('${user?['name']} · $status'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeliveryOrderDetailScreen(
                          orderId: order['id'] as String,
                        ),
                      ),
                    ).then((_) {
                      ref.invalidate(deliveryAssignedProvider);
                    });
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
