import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

final orderDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/orders/$id');
  return res.data as Map<String, dynamic>;
});

const _statusFlow = [
  'PENDING',
  'CONFIRMED',
  'PACKED',
  'OUT_FOR_DELIVERY',
  'DELIVERED',
];

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _pollIfNeeded());
  }

  void _pollIfNeeded() {
    if (!mounted) return;
    final order = ref.read(orderDetailProvider(widget.orderId)).valueOrNull;
    final status = order?['status'] as String?;
    if (status == 'DELIVERED' || status == 'CANCELLED') {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    ref.invalidate(orderDetailProvider(widget.orderId));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(title: const Text('Track order')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.receipt_long_outlined,
          title: 'Could not load order',
          subtitle: 'Check your connection and try again',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
        data: (order) => _OrderTrackingBody(order: order, orderId: widget.orderId),
      ),
    );
  }
}

class _OrderTrackingBody extends StatelessWidget {
  const _OrderTrackingBody({required this.order, required this.orderId});

  final Map<String, dynamic> order;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'PENDING';
    final logs = (order['statusLogs'] as List?) ?? [];
    final assignment = order['deliveryAssignment'] as Map<String, dynamic>?;
    final partner = assignment?['deliveryPartner'] as Map<String, dynamic>?;
    final items = (order['items'] as List?) ?? [];
    final currentIndex = _statusFlow.indexOf(status).clamp(0, _statusFlow.length - 1);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryGreen, Color(0xFF2ECC71)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order['orderNumber'] as String? ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusLabel(status),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    status == 'DELIVERED'
                        ? 'Delivered'
                        : 'ETA: ${_etaFor(status)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text('Order status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(_statusFlow.length, (i) {
          final stepStatus = _statusFlow[i];
          final done = i <= currentIndex;
          final active = i == currentIndex;
          final log = logs.cast<Map<String, dynamic>?>().firstWhere(
                (l) => l?['status'] == stepStatus,
                orElse: () => null,
              );
          return _TimelineStep(
            title: _statusLabel(stepStatus),
            done: done,
            active: active,
            time: log?['createdAt'] as String?,
          );
        }),
        if (partner != null) ...[
          const SizedBox(height: AppSpacing.lg),
          const Text('Delivery partner', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                child: const Icon(Icons.delivery_dining, color: AppColors.primaryGreen),
              ),
              title: Text(partner['name'] as String? ?? 'Partner'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(partner['phone'] as String? ?? ''),
                  const Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      Text(' 4.8 · 500+ deliveries', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.phone, color: AppColors.primaryGreen),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.message_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
        TextButton(
          onPressed: () => context.push('/support'),
          child: const Text('Delivery issue? Contact support'),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text('Order summary', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              ...items.map((item) {
                final i = item as Map<String, dynamic>;
                return ListTile(
                  dense: true,
                  title: Text(i['productName'] as String? ?? ''),
                  trailing: Text('x${i['quantity']}'),
                );
              }),
              const Divider(height: 1),
              ListTile(
                title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(
                  '₹${order['totalAmount']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.support_agent),
                label: const Text('Support'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.replay),
                label: const Text('Reorder'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Order placed';
      case 'CONFIRMED':
        return 'Order confirmed';
      case 'PACKED':
        return 'Being packed';
      case 'OUT_FOR_DELIVERY':
        return 'Out for delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  String _etaFor(String status) {
    switch (status) {
      case 'PENDING':
      case 'CONFIRMED':
        return '30–45 min';
      case 'PACKED':
        return '20–30 min';
      case 'OUT_FOR_DELIVERY':
        return '10–15 min';
      default:
        return 'Soon';
    }
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.done,
    required this.active,
    this.time,
  });

  final String title;
  final bool done;
  final bool active;
  final String? time;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.primaryGreen : AppColors.borderLight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done ? AppColors.primaryGreen : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: done
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            Container(width: 2, height: 32, color: color),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    color: active ? AppColors.navyBlue : AppColors.textDark,
                  ),
                ),
                if (time != null)
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(DateTime.parse(time!)),
                    style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
