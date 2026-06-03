import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/delivery_repository.dart';
import '../providers/delivery_providers.dart';
import '../widgets/delivery_shell.dart';
import 'delivery_earnings_screen.dart';
import 'delivery_history_screen.dart';
import 'delivery_orders_screen.dart';

class DeliveryHomeScreen extends ConsumerStatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  ConsumerState<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends ConsumerState<DeliveryHomeScreen> {
  DeliveryTab _tab = DeliveryTab.orders;
  bool _isOnline = false;

  Future<void> _toggleOnline(bool value) async {
    await ref.read(deliveryRepositoryProvider).updateAvailability(isOnline: value);
    setState(() => _isOnline = value);
    ref.invalidate(deliveryProfileProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(deliveryProfileProvider, (_, next) {
      next.whenData((data) {
        final profile = data['profile'] as Map<String, dynamic>?;
        if (profile != null && mounted) {
          setState(() => _isOnline = profile['isOnline'] as bool? ?? false);
        }
      });
    });
    ref.watch(deliveryProfileProvider);

    Widget body;
    switch (_tab) {
      case DeliveryTab.orders:
        body = const DeliveryOrdersScreen();
      case DeliveryTab.history:
        body = const DeliveryHistoryScreen();
      case DeliveryTab.earnings:
        body = const DeliveryEarningsScreen();
      case DeliveryTab.profile:
        body = const _DeliveryProfileTab();
    }

    return DeliveryShell(
      tab: _tab,
      onTabChanged: (t) => setState(() => _tab = t),
      isOnline: _isOnline,
      onToggleOnline: _toggleOnline,
      child: body,
    );
  }
}

class _DeliveryProfileTab extends ConsumerWidget {
  const _DeliveryProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(deliveryProfileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (data) {
        final user = data['user'] as Map<String, dynamic>? ?? {};
        final profile = data['profile'] as Map<String, dynamic>? ?? {};
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ListTile(
              title: Text(user['name'] as String? ?? 'Partner'),
              subtitle: Text(user['phone'] as String? ?? ''),
            ),
            ListTile(title: Text('Vehicle'), subtitle: Text('${profile['vehicleType'] ?? '—'}')),
            ListTile(title: Text('Rating'), subtitle: Text('${profile['rating'] ?? 5}')),
            ListTile(title: Text('Total deliveries'), subtitle: Text('${profile['totalDeliveries'] ?? 0}')),
          ],
        );
      },
    );
  }
}
