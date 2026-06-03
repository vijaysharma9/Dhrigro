import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/csv_download.dart';
import '../../../../shared/widgets/admin/admin_data_table.dart';
import '../../../../shared/widgets/admin/admin_search_bar.dart';
import '../../../../shared/widgets/admin/order_status_chip.dart';
import '../../data/admin_repository.dart';
import '../providers/admin_providers.dart';

const _orderStatuses = [
  'PENDING',
  'CONFIRMED',
  'PACKED',
  'OUT_FOR_DELIVERY',
  'DELIVERED',
  'CANCELLED',
];

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  late final DebouncedSearch _debouncedSearch;

  @override
  void initState() {
    super.initState();
    _debouncedSearch = DebouncedSearch((q) {
      ref.read(adminOrdersQueryProvider.notifier).update(
            (s) => s.copyWith(search: q, page: 1),
          );
    });
  }

  @override
  void dispose() {
    _debouncedSearch.dispose();
    super.dispose();
  }

  Future<void> _exportCsv() async {
    final query = ref.read(adminOrdersQueryProvider);
    final csv = await ref.read(adminRepositoryProvider).exportOrdersCsv(
          search: query.search,
          status: query.status,
          fromDate: query.fromDate,
          toDate: query.toDate,
        );
    await downloadCsv('orders.csv', csv);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orders CSV downloaded')),
      );
    }
  }

  void _openOrderDetail(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OrderDetailDrawer(
        orderId: order['id'] as String,
        onUpdated: () => ref.invalidate(adminOrdersListProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersListProvider);
    final query = ref.watch(adminOrdersQueryProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Orders', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AdminSearchBar(
                  hint: 'Search order #, name, phone',
                  onChanged: _debouncedSearch,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: query.status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ..._orderStatuses.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s)),
                    ),
                  ],
                  onChanged: (v) {
                    ref.read(adminOrdersQueryProvider.notifier).update(
                          (s) => s.copyWith(status: v, page: 1),
                        );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ordersAsync.when(
              loading: () => const AdminDataTable<Map<String, dynamic>>(
                columns: [],
                rows: [],
                isLoading: true,
              ),
              error: (e, _) => Center(child: Text('$e')),
              data: (res) {
                final rows = (res['data'] as List? ?? [])
                    .cast<Map<String, dynamic>>();
                final meta = res['meta'] as Map<String, dynamic>? ?? {};
                final totalPages = meta['totalPages'] as int? ?? 1;
                final page = meta['page'] as int? ?? 1;

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: AdminDataTable<Map<String, dynamic>>(
                          columns: [
                            AdminColumn(
                              label: 'Order',
                              flex: 2,
                              cellBuilder: (o) => Text(
                                o['orderNumber'] as String? ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            AdminColumn(
                              label: 'Customer',
                              flex: 2,
                              cellBuilder: (o) {
                                final u = o['user'] as Map<String, dynamic>?;
                                return Text(u?['name'] as String? ?? '—');
                              },
                            ),
                            AdminColumn(
                              label: 'Status',
                              cellBuilder: (o) => OrderStatusChip(
                                status: o['status'] as String? ?? '',
                              ),
                            ),
                            AdminColumn(
                              label: 'Total',
                              cellBuilder: (o) => Text('₹${o['totalAmount']}'),
                            ),
                            AdminColumn(
                              label: 'Placed',
                              flex: 2,
                              cellBuilder: (o) {
                                final placed = o['placedAt'] as String?;
                                if (placed == null) return const Text('—');
                                final dt = DateTime.tryParse(placed);
                                return Text(
                                  dt != null
                                      ? DateFormat('dd MMM, HH:mm').format(dt)
                                      : placed,
                                );
                              },
                            ),
                          ],
                          rows: rows,
                          onRowTap: _openOrderDetail,
                        ),
                      ),
                    ),
                    AdminPaginationBar(
                      page: page,
                      totalPages: totalPages,
                      onPageChanged: (p) {
                        ref.read(adminOrdersQueryProvider.notifier).update(
                              (s) => s.copyWith(page: p),
                            );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailDrawer extends ConsumerStatefulWidget {
  const _OrderDetailDrawer({
    required this.orderId,
    required this.onUpdated,
  });

  final String orderId;
  final VoidCallback onUpdated;

  @override
  ConsumerState<_OrderDetailDrawer> createState() => _OrderDetailDrawerState();
}

class _OrderDetailDrawerState extends ConsumerState<_OrderDetailDrawer> {
  String? _selectedStatus;
  String? _selectedSlotId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(adminRepositoryProvider).getOrder(widget.orderId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final order = snap.data!;
        _selectedStatus ??= order['status'] as String?;
        final user = order['user'] as Map<String, dynamic>?;
        final address = order['address'] as Map<String, dynamic>?;
        final items = order['items'] as List? ?? [];
        final logs = order['statusLogs'] as List? ?? [];
        final slotsFuture = ref.read(adminRepositoryProvider).listDeliverySlots();

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: controller,
              children: [
                Text(
                  order['orderNumber'] as String? ?? 'Order',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                OrderStatusChip(status: order['status'] as String? ?? ''),
                const SizedBox(height: 16),
                Text('Customer: ${user?['name']} · ${user?['phone']}'),
                if (address != null)
                  Text(
                    'Address: ${address['line1']}, ${address['city']} ${address['pincode']}',
                  ),
                Text(
                  'Payment: ${order['paymentMethod']} · ${order['paymentStatus']}',
                ),
                Text('Total: ₹${order['totalAmount']}'),
                const Divider(height: 32),
                Text('Items', style: Theme.of(context).textTheme.titleMedium),
                ...items.map((i) {
                  final item = i as Map<String, dynamic>;
                  return ListTile(
                    dense: true,
                    title: Text(item['productName'] as String? ?? ''),
                    trailing: Text('×${item['quantity']}'),
                  );
                }),
                const Divider(height: 32),
                Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
                ...logs.map((l) {
                  final log = l as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.circle, size: 8, color: AppColors.primaryGreen),
                    title: Text(log['status'] as String? ?? ''),
                    subtitle: Text(log['note'] as String? ?? ''),
                  );
                }),
                const Divider(height: 32),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(labelText: 'Update status'),
                  items: _orderStatuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStatus = v),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<dynamic>>(
                  future: slotsFuture,
                  builder: (context, slotSnap) {
                    final slots = slotSnap.data ?? [];
                    return DropdownButtonFormField<String?>(
                      value: _selectedSlotId ?? order['deliverySlotId'] as String?,
                      decoration: const InputDecoration(labelText: 'Delivery slot'),
                      items: slots.map((s) {
                        final slot = s as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: slot['id'] as String,
                          child: Text(
                            '${slot['name'] ?? slot['label'] ?? slot['startTime']} - ${slot['endTime']}',
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedSlotId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _AssignPartnerSection(
                  orderId: widget.orderId,
                  currentPartnerId: (order['assignment'] as Map?)?['deliveryPartnerId'] as String?,
                  onAssigned: widget.onUpdated,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          try {
                            if (_selectedStatus != null &&
                                _selectedStatus != order['status']) {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .updateOrderStatus(
                                    widget.orderId,
                                    status: _selectedStatus!,
                                  );
                            }
                            if (_selectedSlotId != null) {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .assignDeliverySlot(
                                    widget.orderId,
                                    _selectedSlotId!,
                                  );
                            }
                            widget.onUpdated();
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save changes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AssignPartnerSection extends ConsumerStatefulWidget {
  const _AssignPartnerSection({
    required this.orderId,
    this.currentPartnerId,
    required this.onAssigned,
  });

  final String orderId;
  final String? currentPartnerId;
  final VoidCallback onAssigned;

  @override
  ConsumerState<_AssignPartnerSection> createState() =>
      _AssignPartnerSectionState();
}

class _AssignPartnerSectionState extends ConsumerState<_AssignPartnerSection> {
  String? _selectedPartnerId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ref.read(adminRepositoryProvider).listDeliveryPartners(),
      builder: (context, snap) {
        final partners = snap.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String?>(
              value: _selectedPartnerId ?? widget.currentPartnerId,
              decoration: const InputDecoration(labelText: 'Delivery partner'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Unassigned')),
                ...partners.map((p) {
                  final profile = p as Map<String, dynamic>;
                  final user = profile['user'] as Map<String, dynamic>? ?? {};
                  return DropdownMenuItem(
                    value: user['id'] as String,
                    child: Text(
                      '${user['name']} (${profile['isOnline'] == true ? 'online' : 'offline'})',
                    ),
                  );
                }),
              ],
              onChanged: (v) => setState(() => _selectedPartnerId = v),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving || _selectedPartnerId == null
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      try {
                        if (widget.currentPartnerId != null) {
                          await ref
                              .read(adminRepositoryProvider)
                              .reassignDeliveryPartner(
                                orderId: widget.orderId,
                                deliveryPartnerId: _selectedPartnerId!,
                              );
                        } else {
                          await ref
                              .read(adminRepositoryProvider)
                              .assignDeliveryPartner(
                                orderId: widget.orderId,
                                deliveryPartnerId: _selectedPartnerId!,
                              );
                        }
                        widget.onAssigned();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Partner assigned')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.currentPartnerId != null ? 'Reassign' : 'Assign'),
            ),
          ],
        );
      },
    );
  }
}
