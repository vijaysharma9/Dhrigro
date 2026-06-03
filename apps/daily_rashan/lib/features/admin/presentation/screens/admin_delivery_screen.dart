import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/admin_repository.dart';
import '../providers/admin_providers.dart';
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

    return DefaultTabController(
      length: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery', style: Theme.of(context).textTheme.headlineSmall),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Slots'),
                Tab(text: 'Fleet'),
                Tab(text: 'Settings'),
                Tab(text: 'Pincodes'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _SlotsTab(slotsAsync: slotsAsync),
                  const AdminDeliveryFleetScreen(),
                  _SettingsTab(settingsAsync: settingsAsync),
                  const _PincodesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotsTab extends ConsumerWidget {
  const _SlotsTab({required this.slotsAsync});

  final AsyncValue<List<dynamic>> slotsAsync;

  Future<void> _showSlotForm(BuildContext context, WidgetRef ref,
      {Map<String, dynamic>? slot}) async {
    final labelCtrl = TextEditingController(text: slot?['label'] as String?);
    final startCtrl = TextEditingController(text: slot?['startTime'] as String? ?? '09:00');
    final endCtrl = TextEditingController(text: slot?['endTime'] as String? ?? '12:00');
    final capacityCtrl = TextEditingController(text: '${slot?['maxOrders'] ?? 50}');
    final feeCtrl = TextEditingController(text: '${slot?['deliveryFee'] ?? 0}');
    var isActive = slot?['isActive'] as bool? ?? true;
    var sameDay = slot?['isSameDay'] as bool? ?? false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(slot == null ? 'Create slot' : 'Edit slot'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label')),
                TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start (HH:mm)')),
                TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End (HH:mm)')),
                TextField(controller: capacityCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity')),
                TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Delivery fee')),
                SwitchListTile(title: const Text('Same day'), value: sameDay, onChanged: (v) => setLocal(() => sameDay = v)),
                SwitchListTile(title: const Text('Active'), value: isActive, onChanged: (v) => setLocal(() => isActive = v)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final data = {
                  'label': labelCtrl.text.trim(),
                  'startTime': startCtrl.text.trim(),
                  'endTime': endCtrl.text.trim(),
                  'maxOrders': int.tryParse(capacityCtrl.text) ?? 50,
                  'deliveryFee': double.tryParse(feeCtrl.text) ?? 0,
                  'isSameDay': sameDay,
                  'isActive': isActive,
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
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _showSlotForm(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add slot'),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: slotsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (slots) => ListView.builder(
              itemCount: slots.length,
              itemBuilder: (_, i) {
                final s = slots[i] as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text(s['label'] as String? ?? '${s['startTime']}-${s['endTime']}'),
                    subtitle: Text(
                      'Capacity ${s['maxOrders']} · Fee ₹${s['deliveryFee']} · ${s['isSameDay'] == true ? 'Same day' : 'Standard'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showSlotForm(context, ref, slot: s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await ref
                                .read(adminRepositoryProvider)
                                .deleteDeliverySlot(s['id'] as String);
                            ref.invalidate(adminDeliverySlotsProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

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
    return widget.settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (s) {
        if (_minOrderCtrl.text.isEmpty) {
          _minOrderCtrl.text = '${s['minOrderAmount'] ?? 0}';
          _deliveryFeeCtrl.text = '${s['defaultDeliveryFee'] ?? 0}';
          _sameDayEnabled = s['sameDayDeliveryEnabled'] as bool? ?? false;
        }
        return ListView(
          children: [
            TextField(
              controller: _minOrderCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minimum order amount'),
            ),
            TextField(
              controller: _deliveryFeeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Default delivery fee'),
            ),
            SwitchListTile(
              title: const Text('Same day delivery enabled'),
              value: _sameDayEnabled,
              onChanged: (v) => setState(() => _sameDayEnabled = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await ref.read(adminRepositoryProvider).updateDeliverySettings({
                  'minOrderAmount': double.tryParse(_minOrderCtrl.text) ?? 0,
                  'defaultDeliveryFee': double.tryParse(_deliveryFeeCtrl.text) ?? 0,
                  'sameDayDeliveryEnabled': _sameDayEnabled,
                });
                ref.invalidate(adminDeliverySettingsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings saved')),
                  );
                }
              },
              child: const Text('Save settings'),
            ),
          ],
        );
      },
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pincodeCtrl,
                decoration: const InputDecoration(labelText: 'Pincode'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: 'City'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                await ref.read(adminRepositoryProvider).addPincode(
                      _pincodeCtrl.text.trim(),
                      city: _cityCtrl.text.trim(),
                    );
                _pincodeCtrl.clear();
                _cityCtrl.clear();
                await _load();
              },
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _pincodes == null
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _pincodes!.length,
                  itemBuilder: (_, i) {
                    final p = _pincodes![i] as Map<String, dynamic>;
                    return ListTile(
                      title: Text(p['pincode'] as String? ?? ''),
                      subtitle: Text(p['city'] as String? ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                        onPressed: () async {
                          await ref
                              .read(adminRepositoryProvider)
                              .removePincode(p['id'] as String);
                          await _load();
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
