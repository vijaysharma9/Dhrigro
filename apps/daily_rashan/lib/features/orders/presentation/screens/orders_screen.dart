import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';

final ordersProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/orders');
  return res.data as Map<String, dynamic>;
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final orders = (data['data'] as List?) ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final order = orders[i] as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => context.push('/orders/${order['id']}'),
                  title: Text(order['orderNumber'] as String? ?? ''),
                  subtitle: Text(_statusLabel(order['status'] as String?)),
                  trailing: Text(
                    '₹${order['totalAmount']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PACKED':
        return 'Packed';
      case 'OUT_FOR_DELIVERY':
        return 'Out for delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return 'Order placed';
    }
  }
}
