import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/admin/admin_theme.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin/admin_state_widgets.dart';
import '../../../../shared/widgets/admin/admin_stat_card.dart';
import '../providers/admin_providers.dart';
import '../../data/admin_repository.dart';
import '../widgets/admin_delivery_board.dart';
import 'admin_delivery_fleet_screen.dart';

class AdminDeliveryScreen extends ConsumerStatefulWidget {
  const AdminDeliveryScreen({super.key});

  @override
  ConsumerState<AdminDeliveryScreen> createState() => _AdminDeliveryScreenState();
}

class _AdminDeliveryScreenState extends ConsumerState<AdminDeliveryScreen> {
  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(adminDeliverySlotsProvider);
    final settingsAsync = ref.watch(adminDeliverySettingsProvider);
    final opsAsync = ref.watch(adminDeliveryOpsProvider);

    return DefaultTabController(
      length: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AdminSpacing.lg, AdminSpacing.lg, AdminSpacing.lg, 0),
            child: Text('Delivery', style: AdminTypography.pageTitle(context)),
          ),
          opsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (ops) => Padding(
              padding: const EdgeInsets.all(AdminSpacing.lg),
              child: LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth > 900 ? 5 : (c.maxWidth > 500 ? 3 : 2);
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: cols,
                    crossAxisSpacing: AdminSpacing.sm,
                    mainAxisSpacing: AdminSpacing.sm,
                    childAspectRatio: 2.6,
                    children: [
                      AdminStatCard(
                        title: 'Online partners',
                        value: '${ops['partnersOnline'] ?? 0}',
                        icon: Icons.two_wheeler,
                        color: AppColors.primaryGreen,
                        live: true,
                        compact: true,
                      ),
                      AdminStatCard(
                        title: 'Active deliveries',
                        value: '${ops['activeDeliveries'] ?? ops['activeAssignments'] ?? 0}',
                        icon: Icons.local_shipping_outlined,
                        color: AppColors.navyBlue,
                        compact: true,
                      ),
                      AdminStatCard(
                        title: 'Delayed',
                        value: '${ops['delayedDeliveries'] ?? ops['pendingOrders'] ?? 0}',
                        icon: Icons.schedule,
                        color: AdminSemanticColors.warning,
                        compact: true,
                      ),
                      AdminStatCard(
                        title: 'Avg time',
                        value: '${ops['averageDeliveryMinutes'] ?? ops['avgDeliveryMinutes'] ?? 0}m',
                        icon: Icons.timer_outlined,
                        color: AppColors.navyBlue,
                        compact: true,
                      ),
                      AdminStatCard(
                        title: 'Failed',
                        value: '${ops['totalFailed'] ?? 0}',
                        icon: Icons.error_outline,
                        color: AppColors.errorRed,
                        compact: true,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Dispatch board'),
              Tab(text: 'Slots'),
              Tab(text: 'Fleet'),
              Tab(text: 'Settings'),
              Tab(text: 'Pincodes'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const AdminDeliveryBoard(),
                _SlotsTab(slotsAsync: slotsAsync),
                const AdminDeliveryFleetScreen(embedded: true),
                _SettingsTab(settingsAsync: settingsAsync),
                const _PincodesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotsTab extends ConsumerWidget {
  const _SlotsTab({required this.slotsAsync});

  final AsyncValue<List<dynamic>> slotsAsync;

  Future<void> _showSlotForm(BuildContext context, WidgetRef ref,
      {Map<String, dynamic>? slot}) async {
    final labelCtrl = TextEditingController(text: slot?['name'] as String? ?? slot?['label'] as String?);
    final startCtrl = TextEditingController(text: slot?['startTime'] as String? ?? '09:00');
    final endCtrl = TextEditingController(text: slot?['endTime'] as String? ?? '12:00');
    final capacityCtrl = TextEditingController(text: '${slot?['maxOrders'] ?? 50}');
    var isActive = slot?['isActive'] as bool? ?? true;
    final isSameDay = slot?['deliveryType'] == 'SAME_DAY';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(slot == null ? 'Create slot' : 'Edit slot'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start (HH:mm)')),
                  TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End (HH:mm)')),
                  TextField(
                    controller: capacityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacity'),
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setLocal(() => isActive = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final data = {
                  'name': labelCtrl.text.trim(),
                  'startTime': startCtrl.text.trim(),
                  'endTime': endCtrl.text.trim(),
                  'maxOrders': int.tryParse(capacityCtrl.text) ?? 50,
                  'isActive': isActive,
                  'deliveryType': isSameDay ? 'SAME_DAY' : 'NEXT_DAY_MORNING',
                };
                if (slot == null) {
                  await ref.read(adminRepositoryProvider).createDeliverySlot(data);
                } else {
                  await ref.read(adminRepositoryProvider).updateDeliverySlot(
                        slot['id'] as String,
                        data,
                      );
                }
                ref.invalidate(adminDeliverySlotsProvider);
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
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _showSlotForm(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add slot'),
            ),
          ),
          const SizedBox(height: AdminSpacing.md),
          Expanded(
            child: slotsAsync.when(
              loading: () => const AdminLoadingState(compact: true),
              error: (e, _) => AdminErrorState(error: e, onRetry: () => ref.invalidate(adminDeliverySlotsProvider)),
              data: (slots) {
                if (slots.isEmpty) {
                  return const AdminEmptyState(
                    title: 'No delivery slots',
                    message: 'Create slots to manage delivery windows.',
                    icon: Icons.schedule_outlined,
                    actionLabel: 'Add slot',
                  );
                }
                return LayoutBuilder(
                  builder: (context, c) {
                    final cols = c.maxWidth > 900 ? 2 : 1;
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: AdminSpacing.md,
                        mainAxisSpacing: AdminSpacing.md,
                        childAspectRatio: cols == 1 ? 2.8 : 2.4,
                      ),
                      itemCount: slots.length,
                      itemBuilder: (_, i) {
                        final s = slots[i] as Map<String, dynamic>;
                        return _DeliverySlotCard(
                          slot: s,
                          onEdit: () => _showSlotForm(context, ref, slot: s),
                          onDelete: () async {
                            await ref.read(adminRepositoryProvider).deleteDeliverySlot(s['id'] as String);
                            ref.invalidate(adminDeliverySlotsProvider);
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliverySlotCard extends StatelessWidget {
  const _DeliverySlotCard({
    required this.slot,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> slot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final maxOrders = slot['maxOrders'] as int? ?? 50;
    final booked = slot['_count']?['orders'] as int? ?? 0;
    final pct = maxOrders > 0 ? (booked / maxOrders).clamp(0.0, 1.0) : 0.0;
    final isActive = slot['isActive'] as bool? ?? true;
    final isSameDay = slot['deliveryType'] == 'SAME_DAY';
    final healthColor = pct > 0.85
        ? AppColors.errorRed
        : pct > 0.6
            ? AdminSemanticColors.warning
            : AppColors.primaryGreen;

    return Material(
      color: AdminSemanticColors.surfaceCard,
      borderRadius: BorderRadius.circular(AdminRadius.md),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AdminRadius.md),
            border: Border.all(color: AdminSemanticColors.border),
            boxShadow: AdminShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AdminSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        slot['name'] as String? ?? '${slot['startTime']}-${slot['endTime']}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    if (isSameDay)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orangeAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AdminRadius.pill),
                        ),
                        child: const Text(
                          'SAME DAY',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.orangeAccent),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isActive ? AppColors.primaryGreen : AppColors.errorRed).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AdminRadius.pill),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isActive ? AppColors.primaryGreen : AppColors.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${slot['startTime']} – ${slot['endTime']}',
                  style: const TextStyle(fontSize: 11, color: AdminSemanticColors.textMuted),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AdminRadius.pill),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: AdminSemanticColors.borderSubtle,
                          color: healthColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AdminSpacing.sm),
                    Text(
                      '$booked / $maxOrders',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: healthColor),
                    ),
                  ],
                ),
                const SizedBox(height: AdminSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.errorRed),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Settings and Pincodes tabs — compact padding
class _SettingsTab extends ConsumerStatefulWidget {
  const _SettingsTab({required this.settingsAsync});
  final AsyncValue<Map<String, dynamic>> settingsAsync;

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  final _minOrderCtrl = TextEditingController();
  final _deliveryFeeCtrl = TextEditingController();
  var _sameDayEnabled = false;

  @override
  void dispose() {
    _minOrderCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: widget.settingsAsync.when(
        loading: () => const AdminLoadingState(compact: true),
        error: (e, _) => AdminErrorState(error: e, onRetry: () => ref.invalidate(adminDeliverySettingsProvider)),
        data: (s) {
          if (_minOrderCtrl.text.isEmpty) {
            _minOrderCtrl.text = '${s['minOrderAmount'] ?? 0}';
            _deliveryFeeCtrl.text = '${s['defaultDeliveryFee'] ?? 0}';
            _sameDayEnabled = s['sameDayDeliveryEnabled'] as bool? ?? s['sameDayEnabled'] as bool? ?? false;
          }
          return ListView(
            children: [
              TextField(
                controller: _minOrderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minimum order amount', isDense: true),
              ),
              const SizedBox(height: AdminSpacing.md),
              TextField(
                controller: _deliveryFeeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Default delivery fee', isDense: true),
              ),
              SwitchListTile(
                title: const Text('Same day delivery'),
                value: _sameDayEnabled,
                onChanged: (v) => setState(() => _sameDayEnabled = v),
              ),
              FilledButton(
                onPressed: () async {
                  await ref.read(adminRepositoryProvider).updateDeliverySettings({
                    'minOrderAmount': double.tryParse(_minOrderCtrl.text) ?? 0,
                    'defaultDeliveryFee': double.tryParse(_deliveryFeeCtrl.text) ?? 0,
                    'sameDayDeliveryEnabled': _sameDayEnabled,
                  });
                  ref.invalidate(adminDeliverySettingsProvider);
                },
                child: const Text('Save settings'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PincodesTab extends ConsumerStatefulWidget {
  const _PincodesTab();

  @override
  ConsumerState<_PincodesTab> createState() => _PincodesTabState();
}

class _PincodesTabState extends ConsumerState<_PincodesTab> {
  List<dynamic>? _pincodes;
  final _pincodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pincodeCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await ref.read(adminRepositoryProvider).listPincodes();
    if (mounted) setState(() => _pincodes = list);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: TextField(controller: _pincodeCtrl, decoration: const InputDecoration(labelText: 'Pincode', isDense: true))),
              const SizedBox(width: AdminSpacing.sm),
              Expanded(child: TextField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'City', isDense: true))),
              const SizedBox(width: AdminSpacing.sm),
              FilledButton(
                onPressed: () async {
                  await ref.read(adminRepositoryProvider).addPincode(_pincodeCtrl.text.trim(), city: _cityCtrl.text.trim());
                  _pincodeCtrl.clear();
                  _cityCtrl.clear();
                  await _load();
                },
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.md),
          Expanded(
            child: _pincodes == null
                ? const AdminLoadingState(compact: true)
                : ListView.separated(
                    itemCount: _pincodes!.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = _pincodes![i] as Map<String, dynamic>;
                      return ListTile(
                        dense: true,
                        title: Text(p['pincode'] as String? ?? ''),
                        subtitle: Text(p['city'] as String? ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.errorRed),
                          onPressed: () async {
                            await ref.read(adminRepositoryProvider).removePincode(p['id'] as String);
                            await _load();
                          },
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
