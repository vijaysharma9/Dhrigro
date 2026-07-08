import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../shared/providers/storage_provider.dart';
import '../config/env_config.dart';
import 'admin_live_ops.dart';
import '../../features/admin/presentation/providers/admin_providers.dart';

enum RealtimeConnectionState { disconnected, connecting, connected, polling }

class AdminRealtimeState {
  const AdminRealtimeState({
    this.connection = RealtimeConnectionState.polling,
    this.lastEvent,
    this.usePollingFallback = true,
  });

  final RealtimeConnectionState connection;
  final String? lastEvent;
  final bool usePollingFallback;

  AdminRealtimeState copyWith({
    RealtimeConnectionState? connection,
    String? lastEvent,
    bool? usePollingFallback,
  }) {
    return AdminRealtimeState(
      connection: connection ?? this.connection,
      lastEvent: lastEvent ?? this.lastEvent,
      usePollingFallback: usePollingFallback ?? this.usePollingFallback,
    );
  }
}

final adminRealtimeProvider =
    NotifierProvider<AdminRealtimeNotifier, AdminRealtimeState>(
  AdminRealtimeNotifier.new,
);

/// WebSocket layer with automatic polling fallback.
class AdminRealtimeNotifier extends Notifier<AdminRealtimeState> {
  io.Socket? _socket;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  @override
  AdminRealtimeState build() {
    ref.onDispose(_disconnect);
    Future.microtask(_connect);
    return const AdminRealtimeState();
  }

  Future<void> _connect() async {
    // WebSocket client can crash Flutter web at runtime; use polling there.
    if (kIsWeb || !EnvConfig.realtimeEnabled) {
      state = const AdminRealtimeState(
        connection: RealtimeConnectionState.polling,
        usePollingFallback: false,
      );
      return;
    }

    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: StorageKeys.accessToken);
    if (token == null || token.isEmpty) return;

    state = state.copyWith(connection: RealtimeConnectionState.connecting);

    try {
      _socket?.dispose();
      _socket = io.io(
        '${EnvConfig.realtimeBaseUrl}/realtime',
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .setAuth({'token': token})
            .build(),
      );

      _socket!
        ..onConnect((_) {
          _reconnectAttempts = 0;
          state = state.copyWith(
            connection: RealtimeConnectionState.connected,
            usePollingFallback: false,
          );
        })
        ..onDisconnect((_) {
          state = state.copyWith(
            connection: RealtimeConnectionState.disconnected,
            usePollingFallback: true,
          );
          _scheduleReconnect();
        })
        ..onConnectError((err) {
          if (kDebugMode) debugPrint('WS connect error: $err');
          state = state.copyWith(
            connection: RealtimeConnectionState.polling,
            usePollingFallback: true,
          );
          _scheduleReconnect();
        })
        ..on('event', (data) {
          if (data is! Map) return;
          final event = Map<String, dynamic>.from(data);
          final type = event['type'] as String? ?? '';
          state = state.copyWith(lastEvent: type);
          _invalidateForEvent(type);
        });

      _socket!.connect();
    } catch (e) {
      state = state.copyWith(
        connection: RealtimeConnectionState.polling,
        usePollingFallback: true,
      );
      _scheduleReconnect();
    }
  }

  void _invalidateForEvent(String type) {
    ref.read(adminLastSyncProvider.notifier).state = DateTime.now();
    switch (type) {
      case 'order_created':
      case 'order_updated':
      case 'order_assigned':
      case 'payment_failed':
        ref.invalidate(adminOrdersListProvider);
        ref.invalidate(adminDashboardProvider);
        ref.invalidate(adminDeliveryBoardProvider);
      case 'stock_low':
        ref.invalidate(adminInventoryListProvider);
        ref.invalidate(adminDashboardProvider);
      case 'notification_created':
        ref.invalidate(adminDashboardProvider);
      case 'partner_location':
        ref.invalidate(adminDeliveryOpsProvider);
      default:
        ref.invalidate(adminDashboardProvider);
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= 5) return;
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delay = Duration(seconds: 2 * _reconnectAttempts);
    _reconnectTimer = Timer(delay, _connect);
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _socket?.dispose();
    _socket = null;
  }

  void reconnect() {
    _reconnectAttempts = 0;
    _connect();
  }
}
