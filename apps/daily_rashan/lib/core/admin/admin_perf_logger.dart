import 'package:flutter/foundation.dart';

/// Lightweight client-side performance logger for admin ops.
class AdminPerfLogger {
  AdminPerfLogger._();

  static final _routeTimings = <String, List<int>>{};
  static final _slowRenders = <String>[];

  static void trackRoute(String route, int ms) {
    _routeTimings.putIfAbsent(route, () => []).add(ms);
    if (ms > 500 && kDebugMode) {
      debugPrint('[AdminPerf] Slow route $route: ${ms}ms');
    }
  }

  static void trackRender(String widget, int ms) {
    if (ms > 16) {
      _slowRenders.add('$widget:${ms}ms');
      if (_slowRenders.length > 50) _slowRenders.removeAt(0);
      if (ms > 100 && kDebugMode) {
        debugPrint('[AdminPerf] Slow render $widget: ${ms}ms');
      }
    }
  }

  static Map<String, dynamic> snapshot() => {
        'routes': _routeTimings.map(
          (k, v) => MapEntry(k, {
            'count': v.length,
            'avgMs': v.isEmpty ? 0 : v.reduce((a, b) => a + b) ~/ v.length,
          }),
        ),
        'slowRenders': List<String>.from(_slowRenders.take(10)),
      };
}
