import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

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
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.receipt_long_outlined,
          title: 'Could not load orders',
          subtitle: 'Check your connection and try again',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(ordersProvider),
        ),
        data: (data) {
          final orders = (data['data'] as List?) ?? [];
          if (orders.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Your order history will show up here',
              actionLabel: 'Start shopping',
              onAction: () => context.go('/home'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final order = orders[i] as Map<String, dynamic>;
              final status = order['status'] as String? ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                  onTap: () => context.push('/orders/${order['id']}'),
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(status).withValues(alpha: 0.12),
                    child: Icon(_statusIcon(status), color: _statusColor(status), size: 20),
                  ),
                  title: Text(
                    order['orderNumber'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(_statusLabel(status)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order['totalAmount']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'DELIVERED':
        return AppColors.successGreen;
      case 'CANCELLED':
        return AppColors.errorRed;
      case 'OUT_FOR_DELIVERY':
        return AppColors.orangeAccent;
      default:
        return AppColors.navyBlue;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'DELIVERED':
        return Icons.check_circle;
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
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
        return status?.replaceAll('_', ' ') ?? '';
    }
  }
}
