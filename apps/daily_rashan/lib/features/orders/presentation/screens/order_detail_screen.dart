import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';

final orderDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/orders/$id');
  return res.data as Map<String, dynamic>;
});

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (order) {
          final logs = (order['statusLogs'] as List?) ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                order['orderNumber'] as String? ?? '',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Total: ₹${order['totalAmount']}'),
              const SizedBox(height: 24),
              const Text(
                'Order timeline',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ...logs.map((log) {
                final l = log as Map<String, dynamic>;
                return _TimelineTile(
                  status: l['status'] as String? ?? '',
                  note: l['note'] as String?,
                  time: l['createdAt'] as String?,
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.status,
    this.note,
    this.time,
  });

  final String status;
  final String? note;
  final String? time;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(status.replaceAll('_', ' '),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (note != null) Text(note!, style: const TextStyle(fontSize: 12)),
              if (time != null)
                Text(time!, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
