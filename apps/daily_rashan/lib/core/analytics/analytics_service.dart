import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Analytics abstraction — ready for Firebase Analytics swap-in.
abstract class AnalyticsService {
  void track(String event, [Map<String, Object?> params = const {}]);
}

class DebugAnalyticsService implements AnalyticsService {
  @override
  void track(String event, [Map<String, Object?> params = const {}]) {
    if (kDebugMode) {
      debugPrint('[Analytics] $event ${params.isEmpty ? '' : params}');
    }
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return DebugAnalyticsService();
});

class AnalyticsEvents {
  AnalyticsEvents._();

  static const productViewed = 'product_viewed';
  static const searchPerformed = 'search_performed';
  static const addToCart = 'add_to_cart';
  static const checkoutStarted = 'checkout_started';
  static const orderPlaced = 'order_placed';
  static const couponApplied = 'coupon_applied';
  static const reorderAll = 'reorder_all';
  static const reorderItem = 'reorder_item';
}

extension AnalyticsRef on WidgetRef {
  void trackEvent(String event, [Map<String, Object?> params = const {}]) {
    read(analyticsServiceProvider).track(event, params);
  }
}
