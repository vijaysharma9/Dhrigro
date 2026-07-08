import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/admin/admin_api_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin/admin_data_table.dart';
import '../../../../shared/widgets/admin/admin_state_widgets.dart';
import '../../data/admin_repository.dart';
import '../providers/admin_providers.dart';

class AdminCouponsScreen extends ConsumerWidget {
  const AdminCouponsScreen({super.key});

  void _showForm(BuildContext context, WidgetRef ref, {Map<String, dynamic>? coupon}) {
    final codeCtrl = TextEditingController(text: coupon?['code'] as String?);
    final descCtrl = TextEditingController(text: coupon?['description'] as String?);
    final minCtrl = TextEditingController(
      text: '${coupon?['minOrderAmount'] ?? 0}',
    );
    final valueCtrl = TextEditingController(
      text: '${coupon?['discountValue'] ?? 10}',
    );
    final maxUsesCtrl = TextEditingController(
      text: '${coupon?['maxUses'] ?? 100}',
    );
    var type = coupon?['discountType'] as String? ?? 'PERCENTAGE';
    var isActive = coupon?['isActive'] as bool? ?? true;
    DateTime? expires = coupon?['expiresAt'] != null
        ? DateTime.tryParse(coupon!['expiresAt'] as String)
        : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(coupon == null ? 'Create coupon' : 'Edit coupon'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'Code'),
                  ),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Discount type'),
                    items: const [
                      DropdownMenuItem(value: 'PERCENTAGE', child: Text('Percentage')),
                      DropdownMenuItem(value: 'FIXED', child: Text('Fixed amount')),
                    ],
                    onChanged: (v) => setLocal(() => type = v ?? type),
                  ),
                  TextField(
                    controller: valueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Discount value'),
                  ),
                  TextField(
                    controller: minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min order amount'),
                  ),
                  TextField(
                    controller: maxUsesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max uses'),
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setLocal(() => isActive = v),
                  ),
                  ListTile(
                    title: Text(
                      expires == null
                          ? 'No expiry'
                          : 'Expires: ${expires!.toLocal()}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (picked != null) setLocal(() => expires = picked);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final payload = {
                  'code': codeCtrl.text.trim().toUpperCase(),
                  'description': descCtrl.text.trim(),
                  'discountType': type,
                  'discountValue': double.tryParse(valueCtrl.text) ?? 0,
                  'minOrderAmount': double.tryParse(minCtrl.text) ?? 0,
                  'maxUses': int.tryParse(maxUsesCtrl.text) ?? 100,
                  'isActive': isActive,
                  if (expires != null) 'expiresAt': expires!.toIso8601String(),
                };
                if (coupon == null) {
                  await ref.read(adminRepositoryProvider).createCoupon(payload);
                } else {
                  await ref.read(adminRepositoryProvider).updateCoupon(
                        coupon['id'] as String,
                        payload,
                      );
                }
                ref.invalidate(adminCouponsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(adminCouponsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Coupons', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showForm(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('New coupon'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: couponsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AdminErrorState(
                error: e,
                title: 'Could not load coupons',
                onRetry: () => ref.invalidate(adminCouponsProvider),
              ),
              data: (list) {
                final rows = AdminApiUtils.asMapList(list);
                return SingleChildScrollView(
                  child: AdminDataTable<Map<String, dynamic>>(
                    columns: [
                      AdminColumn(
                        label: 'Code',
                        flex: 2,
                        cellBuilder: (c) => Text(
                          c['code'] as String? ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      AdminColumn(
                        label: 'Type',
                        cellBuilder: (c) => Text(c['discountType'] as String? ?? ''),
                      ),
                      AdminColumn(
                        label: 'Value',
                        cellBuilder: (c) => Text('${c['discountValue']}'),
                      ),
                      AdminColumn(
                        label: 'Used',
                        cellBuilder: (c) =>
                            Text('${c['usedCount'] ?? 0}/${c['maxUses'] ?? '∞'}'),
                      ),
                      AdminColumn(
                        label: 'Status',
                        cellBuilder: (c) {
                          final active = c['isActive'] as bool? ?? false;
                          return Chip(
                            label: Text(active ? 'Active' : 'Disabled'),
                            backgroundColor: active
                                ? AppColors.primaryGreen.withValues(alpha: 0.12)
                                : Colors.grey.shade200,
                          );
                        },
                      ),
                      AdminColumn(
                        label: '',
                        cellBuilder: (c) => Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showForm(context, ref, coupon: c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await ref
                                    .read(adminRepositoryProvider)
                                    .deleteCoupon(c['id'] as String);
                                ref.invalidate(adminCouponsProvider);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    rows: rows,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
