import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/delivery_providers.dart';

class DeliveryHistoryScreen extends ConsumerWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(deliveryHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (res) {
        final list = (res['data'] as List? ?? []).cast<Map<String, dynamic>>();
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(deliveryHistoryProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final a = list[i];
              final order = a['order'] as Map<String, dynamic>? ?? {};
              return ListTile(
                title: Text(order['orderNumber'] as String? ?? ''),
                subtitle: Text(a['status'] as String? ?? ''),
                trailing: Text('₹${a['earningAmount'] ?? 0}'),
              );
            },
          ),
        );
      },
    );
  }
}
