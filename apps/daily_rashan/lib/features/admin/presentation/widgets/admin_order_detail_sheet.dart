import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/admin/admin_api_utils.dart';
import '../../../../core/admin/admin_theme.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin/admin_ops_widgets.dart';
import '../../../../shared/widgets/admin/admin_state_widgets.dart';
import '../../../../shared/widgets/admin/admin_toast.dart';
import '../../../../shared/widgets/admin/order_status_chip.dart';
import '../../data/admin_repository.dart';
import '../utils/order_invoice_printer.dart';

const orderStatuses = [
  'PENDING',
  'CONFIRMED',
  'PACKED',
  'OUT_FOR_DELIVERY',
  'DELIVERED',
  'CANCELLED',
];

void showAdminOrderDetailSheet(
  BuildContext context, {
  required String orderId,
  required VoidCallback onUpdated,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AdminOrderDetailSheet(orderId: orderId, onUpdated: onUpdated),
  );
}

class AdminOrderDetailSheet extends ConsumerStatefulWidget {
  const AdminOrderDetailSheet({
    super.key,
    required this.orderId,
    required this.onUpdated,
  });

  final String orderId;
  final VoidCallback onUpdated;

  @override
  ConsumerState<AdminOrderDetailSheet> createState() => _AdminOrderDetailSheetState();
}

class _AdminOrderDetailSheetState extends ConsumerState<AdminOrderDetailSheet> {
  String? _selectedStatus;
  String? _selectedSlotId;
  bool _saving = false;
  int _reloadTick = 0;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AdminSemanticColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AdminRadius.lg)),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          key: ValueKey(_reloadTick),
          future: ref.read(adminRepositoryProvider).getOrder(widget.orderId),
          builder: (context, snap) {
            if (snap.hasError) {
              return AdminErrorState(
                error: snap.error!,
                title: 'Could not load order',
                onRetry: () => setState(() => _reloadTick++),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }

            final order = snap.data!;
            _selectedStatus ??= order['status'] as String?;
            final user = AdminApiUtils.asMapOrNull(order['user']);
            final address = AdminApiUtils.asMapOrNull(order['address']);
            final items = order['items'] as List? ?? [];
            final logs = order['statusLogs'] as List? ?? [];
            final assignment = AdminApiUtils.asMapOrNull(order['assignment']);
            final partner = AdminApiUtils.asMapOrNull(assignment?['partner']);

            return Column(
              children: [
                const SizedBox(height: AdminSpacing.sm),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AdminSemanticColors.border,
                    borderRadius: BorderRadius.circular(AdminRadius.pill),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(AdminSpacing.lg),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order['orderNumber'] as String? ?? 'Order',
                                  style: AdminTypography.pageTitle(context),
                                ),
                                const SizedBox(height: 4),
                                OrderStatusChip(status: order['status'] as String? ?? ''),
                              ],
                            ),
                          ),
                          if (user != null) AdminAvatar(name: user['name'] as String?, size: 40),
                        ],
                      ),
                      const SizedBox(height: AdminSpacing.lg),
                      AdminSectionCard(
                        title: 'Customer',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?['name'] as String? ?? '—',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(user?['phone'] as String? ?? '',
                                style: const TextStyle(fontSize: 12, color: AdminSemanticColors.textMuted)),
                            if (address != null) ...[
                              const SizedBox(height: AdminSpacing.sm),
                              Text(
                                '${address['addressLine1'] ?? address['line1'] ?? ''}, '
                                '${address['city'] ?? ''} ${address['pincode'] ?? ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                      AdminSectionCard(
                        title: 'Payment summary',
                        child: Column(
                          children: [
                            _SummaryRow('Subtotal', '₹${order['subtotal']}'),
                            _SummaryRow('Delivery', '₹${order['deliveryFee']}'),
                            if ((order['discountAmount'] as num? ?? 0) > 0)
                              _SummaryRow('Discount', '-₹${order['discountAmount']}'),
                            const Divider(height: AdminSpacing.lg),
                            _SummaryRow(
                              'Total',
                              '₹${order['totalAmount']}',
                              bold: true,
                            ),
                            const SizedBox(height: AdminSpacing.sm),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                AdminMetaChip(
                                  label: '${order['paymentMethod']}',
                                  icon: Icons.payment_outlined,
                                ),
                                AdminMetaChip(
                                  label: '${order['paymentStatus']}',
                                  color: order['paymentStatus'] == 'FAILED'
                                      ? AppColors.errorRed
                                      : AppColors.primaryGreen,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (partner != null)
                        AdminSectionCard(
                          title: 'Delivery partner',
                          child: Row(
                            children: [
                              const AdminAvatar(name: 'P', size: 36),
                              const SizedBox(width: AdminSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(partner['name'] as String? ?? 'Partner',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(partner['phone'] as String? ?? '',
                                        style: const TextStyle(fontSize: 11, color: AdminSemanticColors.textMuted)),
                                  ],
                                ),
                              ),
                              const AdminMetaChip(label: 'Assigned', color: AppColors.navyBlue),
                            ],
                          ),
                        ),
                      AdminSectionCard(
                        title: 'Items (${items.length})',
                        child: Column(
                          children: items.map((raw) {
                            final item = raw as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(child: Text(item['productName'] as String? ?? '')),
                                  Text('×${item['quantity']}'),
                                  const SizedBox(width: AdminSpacing.md),
                                  Text('₹${item['totalPrice']}',
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      AdminSectionCard(
                        title: 'Timeline',
                        child: Column(
                          children: logs.asMap().entries.map((e) {
                            final log = e.value as Map<String, dynamic>;
                            final isLast = e.key == logs.length - 1;
                            return _TimelineTile(
                              status: log['status'] as String? ?? '',
                              note: log['note'] as String?,
                              isLast: isLast,
                            );
                          }).toList(),
                        ),
                      ),
                      AdminSectionCard(
                        title: 'Update order',
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                isDense: true,
                              ),
                              items: orderStatuses
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedStatus = v),
                            ),
                            const SizedBox(height: AdminSpacing.sm),
                            FutureBuilder<List<dynamic>>(
                              future: ref.read(adminRepositoryProvider).listDeliverySlots(),
                              builder: (context, slotSnap) {
                                final slots = slotSnap.data ?? [];
                                return DropdownButtonFormField<String?>(
                                  value: _selectedSlotId ?? order['deliverySlotId'] as String?,
                                  decoration: const InputDecoration(
                                    labelText: 'Delivery slot',
                                    isDense: true,
                                  ),
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
                            const SizedBox(height: AdminSpacing.md),
                            _AssignPartnerSection(
                              orderId: widget.orderId,
                              currentPartnerId: assignment?['deliveryPartnerId'] as String?,
                              onAssigned: widget.onUpdated,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                _StickyFooter(
                  saving: _saving,
                  onSave: () => _save(order),
                  onPrint: () => _printInvoice(order),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _printInvoice(Map<String, dynamic> order) async {
    try {
      await OrderInvoicePrinter.printOrders([order]);
      if (mounted) AdminToast.success(context, 'Invoice ready to print');
    } catch (e) {
      if (mounted) AdminToast.errorFrom(context, e);
    }
  }

  Future<void> _save(Map<String, dynamic> order) async {
    setState(() => _saving = true);
    try {
      if (_selectedStatus != null && _selectedStatus != order['status']) {
        await ref.read(adminRepositoryProvider).updateOrderStatus(
              widget.orderId,
              status: _selectedStatus!,
            );
      }
      if (_selectedSlotId != null) {
        await ref.read(adminRepositoryProvider).assignDeliverySlot(
              widget.orderId,
              _selectedSlotId!,
            );
      }
      widget.onUpdated();
      if (mounted) {
        AdminToast.success(context, 'Order updated');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AdminToast.errorFrom(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.status,
    this.note,
    required this.isLast,
  });

  final String status;
  final String? note;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AdminSemanticColors.borderSubtle),
                ),
            ],
          ),
          const SizedBox(width: AdminSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AdminSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status.replaceAll('_', ' '),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  if (note != null && note!.isNotEmpty)
                    Text(note!, style: const TextStyle(fontSize: 11, color: AdminSemanticColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyFooter extends StatelessWidget {
  const _StickyFooter({
    required this.saving,
    required this.onSave,
    required this.onPrint,
  });

  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: AdminSemanticColors.surfaceCard,
        border: Border(top: BorderSide(color: AdminSemanticColors.border)),
        boxShadow: AdminShadows.card,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: saving ? null : onPrint,
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text('Print'),
            ),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: saving ? null : onSave,
                child: saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
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
  ConsumerState<_AssignPartnerSection> createState() => _AssignPartnerSectionState();
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
        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _selectedPartnerId ?? widget.currentPartnerId,
                decoration: const InputDecoration(
                  labelText: 'Partner',
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Unassigned')),
                  ...partners.map((p) {
                    final profile = p as Map<String, dynamic>;
                    final user = profile['user'] as Map<String, dynamic>? ?? {};
                    return DropdownMenuItem(
                      value: user['id'] as String,
                      child: Text(
                        '${user['name']} (${profile['isOnline'] == true ? 'online' : 'off'})',
                      ),
                    );
                  }),
                ],
                onChanged: (v) => setState(() => _selectedPartnerId = v),
              ),
            ),
            const SizedBox(width: AdminSpacing.sm),
            FilledButton.tonal(
              onPressed: _saving || _selectedPartnerId == null
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      try {
                        if (widget.currentPartnerId != null) {
                          await ref.read(adminRepositoryProvider).reassignDeliveryPartner(
                                orderId: widget.orderId,
                                deliveryPartnerId: _selectedPartnerId!,
                              );
                        } else {
                          await ref.read(adminRepositoryProvider).assignDeliveryPartner(
                                orderId: widget.orderId,
                                deliveryPartnerId: _selectedPartnerId!,
                              );
                        }
                        widget.onAssigned();
                        if (context.mounted) AdminToast.success(context, 'Partner assigned');
                      } catch (e) {
                        if (context.mounted) AdminToast.errorFrom(context, e);
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(widget.currentPartnerId != null ? 'Reassign' : 'Assign'),
            ),
          ],
        );
      },
    );
  }
}

List<Widget> buildOrderMetaChips(Map<String, dynamic> order) {
  final chips = <Widget>[];
  final method = (order['paymentMethod'] as String? ?? '').toUpperCase();
  if (method == 'COD') {
    chips.add(const AdminMetaChip(label: 'COD', icon: Icons.payments_outlined, color: AppColors.navyBlue));
  } else if (method.contains('RAZOR')) {
    chips.add(const AdminMetaChip(label: 'Razorpay', icon: Icons.credit_card, color: AppColors.primaryGreen));
  }

  if (order['paymentStatus'] == 'FAILED') {
    chips.add(const AdminMetaChip(label: 'Failed', color: AppColors.errorRed));
  }

  final status = order['status'] as String? ?? '';
  if (status == 'PENDING' || status == 'CONFIRMED') {
    final placed = order['placedAt'] as String?;
    if (placed != null) {
      final dt = DateTime.tryParse(placed);
      if (dt != null && DateTime.now().difference(dt).inHours > 2) {
        chips.add(const AdminMetaChip(label: 'Delayed', color: AdminSemanticColors.warning));
      }
    }
  }

  if (order['assignment'] != null) {
    chips.add(const AdminMetaChip(label: 'Assigned', color: AppColors.navyBlue));
  }

  if (status == 'DELIVERED') {
    chips.add(const AdminMetaChip(label: 'Delivered', color: AppColors.primaryGreen));
  }

  return chips;
}

String formatOrderPlaced(String? placed) {
  if (placed == null) return '—';
  final dt = DateTime.tryParse(placed);
  if (dt == null) return placed;
  return DateFormat('dd MMM, HH:mm').format(dt);
}
