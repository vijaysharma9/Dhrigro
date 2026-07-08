import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin/admin_api_utils.dart';
import '../../features/admin/data/admin_repository.dart';
import '../../features/admin/presentation/providers/admin_providers.dart';

/// Backend connectivity states for admin ops console.
enum AdminConnectionStatus { connected, degraded, disconnected }

class AdminConnectionState {
  const AdminConnectionState({
    required this.status,
    this.lastChecked,
    this.latencyMs,
    this.message,
  });

  final AdminConnectionStatus status;
  final DateTime? lastChecked;
  final int? latencyMs;
  final String? message;
}

final adminConnectionProvider =
    NotifierProvider<AdminConnectionNotifier, AdminConnectionState>(
  AdminConnectionNotifier.new,
);

class AdminConnectionNotifier extends Notifier<AdminConnectionState> {
  Timer? _timer;

  @override
  AdminConnectionState build() {
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => checkHealth());
    Future.microtask(checkHealth);
    return const AdminConnectionState(status: AdminConnectionStatus.connected);
  }

  Future<void> checkHealth() async {
    final sw = Stopwatch()..start();
    try {
      await ref.read(adminRepositoryProvider).pingHealth();
      sw.stop();
      final ms = sw.elapsedMilliseconds;
      state = AdminConnectionState(
        status: ms > 2000
            ? AdminConnectionStatus.degraded
            : AdminConnectionStatus.connected,
        lastChecked: DateTime.now(),
        latencyMs: ms,
      );
    } catch (e) {
      state = AdminConnectionState(
        status: AdminConnectionStatus.disconnected,
        lastChecked: DateTime.now(),
        message: '$e',
      );
    }
  }
}

enum LiveOpsEventType {
  orderCreated,
  orderAssigned,
  orderDelayed,
  paymentFailed,
  inventoryLow,
  userSignup,
  partnerOffline,
}

enum LiveOpsSeverity { info, success, warning, critical, live }

class LiveOpsEvent {
  const LiveOpsEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.severity,
  });

  final String id;
  final LiveOpsEventType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final LiveOpsSeverity severity;
}

List<LiveOpsEvent> buildLiveOpsEvents(Map<String, dynamic> dashboard) {
  final events = <LiveOpsEvent>[];
  final now = DateTime.now();

  for (final raw in (dashboard['recentOrders'] as List? ?? []).take(8)) {
    if (raw is! Map) continue;
    final o = AdminApiUtils.asMap(raw);
    final id = o['id'] as String? ?? '${o['orderNumber']}';
    final placed = DateTime.tryParse(o['placedAt'] as String? ?? '') ?? now;
    final status = o['status'] as String? ?? '';

    if (o['paymentStatus'] == 'FAILED') {
      events.add(LiveOpsEvent(
        id: 'pay-$id',
        type: LiveOpsEventType.paymentFailed,
        title: 'Payment failed',
        subtitle: '#${o['orderNumber']} · ₹${o['totalAmount']}',
        timestamp: placed,
        severity: LiveOpsSeverity.critical,
      ));
    } else {
      events.add(LiveOpsEvent(
        id: 'ord-$id',
        type: LiveOpsEventType.orderCreated,
        title: 'New order',
        subtitle: '#${o['orderNumber']} · $status',
        timestamp: placed,
        severity: LiveOpsSeverity.success,
      ));
    }

    if (o['assignment'] != null) {
      events.add(LiveOpsEvent(
        id: 'asg-$id',
        type: LiveOpsEventType.orderAssigned,
        title: 'Delivery assigned',
        subtitle: '#${o['orderNumber']}',
        timestamp: placed.add(const Duration(minutes: 5)),
        severity: LiveOpsSeverity.live,
      ));
    }

    if ((status == 'PENDING' || status == 'CONFIRMED') &&
        now.difference(placed).inHours > 2) {
      events.add(LiveOpsEvent(
        id: 'dly-$id',
        type: LiveOpsEventType.orderDelayed,
        title: 'Order delayed',
        subtitle: '#${o['orderNumber']}',
        timestamp: placed,
        severity: LiveOpsSeverity.warning,
      ));
    }
  }

  for (final raw in (dashboard['lowStockProducts'] as List? ?? []).take(4)) {
    if (raw is! Map) continue;
    final p = AdminApiUtils.asMap(raw);
    events.add(LiveOpsEvent(
      id: 'stk-${p['id']}',
      type: LiveOpsEventType.inventoryLow,
      title: 'Low stock',
      subtitle: '${p['name']} · ${p['stock']} left',
      timestamp: now.subtract(const Duration(minutes: 10)),
      severity: LiveOpsSeverity.warning,
    ));
  }

  final ops = AdminApiUtils.asMapOrNull(dashboard['deliveryOps']) ?? {};
  if ((ops['partnersOnline'] as int? ?? 0) == 0 &&
      (ops['activeDeliveries'] as int? ?? 0) > 0) {
    events.add(LiveOpsEvent(
      id: 'prt-offline',
      type: LiveOpsEventType.partnerOffline,
      title: 'No partners online',
      subtitle: '${ops['activeDeliveries']} deliveries pending',
      timestamp: now,
      severity: LiveOpsSeverity.critical,
    ));
  }

  events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return events.take(20).toList();
}

final adminLiveEventsProvider = FutureProvider.autoDispose<List<LiveOpsEvent>>((ref) async {
  final dash = await ref.watch(adminDashboardProvider.future);
  return buildLiveOpsEvents(dash);
});

final adminLastSyncProvider = StateProvider<DateTime?>((ref) => null);
final adminSilentSyncProvider = StateProvider<bool>((ref) => false);

/// Section-aware polling — call from AdminHomeScreen.
class AdminSectionPoller {
  AdminSectionPoller(this.ref);
  final WidgetRef ref;
  Timer? _timer;

  void start(void Function() onTick, Duration interval) {
    _timer?.cancel();
    onTick();
    _timer = Timer.periodic(interval, (_) {
      ref.read(adminSilentSyncProvider.notifier).state = true;
      onTick();
      ref.read(adminLastSyncProvider.notifier).state = DateTime.now();
      Future.delayed(const Duration(milliseconds: 600), () {
        ref.read(adminSilentSyncProvider.notifier).state = false;
      });
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
