import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'customer_prefs_provider.dart';
import '../../shared/providers/storage_provider.dart';

class CustomerInsightsKeys {
  CustomerInsightsKeys._();
  static const recentlyViewed = 'customer_recently_viewed';
  static const purchaseCounts = 'customer_purchase_counts';
  static const loyaltyPoints = 'customer_loyalty_points';
  static const totalSavings = 'customer_total_savings';
  static const monthlySavings = 'customer_monthly_savings';
  static const ordersPlaced = 'customer_orders_placed';
}

class CustomerInsights {
  const CustomerInsights({
    this.recentlyViewed = const [],
    this.purchaseCounts = const {},
    this.loyaltyPoints = 0,
    this.totalSavings = 0,
    this.monthlySavings = 0,
    this.ordersPlaced = 0,
  });

  final List<String> recentlyViewed;
  final Map<String, int> purchaseCounts;
  final int loyaltyPoints;
  final double totalSavings;
  final double monthlySavings;
  final int ordersPlaced;

  CustomerInsights copyWith({
    List<String>? recentlyViewed,
    Map<String, int>? purchaseCounts,
    int? loyaltyPoints,
    double? totalSavings,
    double? monthlySavings,
    int? ordersPlaced,
  }) {
    return CustomerInsights(
      recentlyViewed: recentlyViewed ?? this.recentlyViewed,
      purchaseCounts: purchaseCounts ?? this.purchaseCounts,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalSavings: totalSavings ?? this.totalSavings,
      monthlySavings: monthlySavings ?? this.monthlySavings,
      ordersPlaced: ordersPlaced ?? this.ordersPlaced,
    );
  }
}

final customerInsightsProvider =
    AsyncNotifierProvider<CustomerInsightsNotifier, CustomerInsights>(
  CustomerInsightsNotifier.new,
);

class CustomerInsightsNotifier extends AsyncNotifier<CustomerInsights> {
  @override
  Future<CustomerInsights> build() async {
    final sp = await ref.watch(sharedPrefsProvider.future);
    List<String> viewed = [];
    Map<String, int> counts = {};
    try {
      final v = sp.getString(CustomerInsightsKeys.recentlyViewed);
      if (v != null) viewed = List<String>.from(jsonDecode(v) as List);
      final c = sp.getString(CustomerInsightsKeys.purchaseCounts);
      if (c != null) {
        counts = Map<String, int>.from(
          (jsonDecode(c) as Map).map((k, v) => MapEntry(k.toString(), v as int)),
        );
      }
    } catch (_) {}
    return CustomerInsights(
      recentlyViewed: viewed,
      purchaseCounts: counts,
      loyaltyPoints: sp.getInt(CustomerInsightsKeys.loyaltyPoints) ?? 0,
      totalSavings: sp.getDouble(CustomerInsightsKeys.totalSavings) ?? 0,
      monthlySavings: sp.getDouble(CustomerInsightsKeys.monthlySavings) ?? 0,
      ordersPlaced: sp.getInt(CustomerInsightsKeys.ordersPlaced) ?? 0,
    );
  }

  Future<void> _persist(CustomerInsights insights) async {
    final sp = await ref.read(sharedPrefsProvider.future);
    await sp.setString(
      CustomerInsightsKeys.recentlyViewed,
      jsonEncode(insights.recentlyViewed),
    );
    await sp.setString(
      CustomerInsightsKeys.purchaseCounts,
      jsonEncode(insights.purchaseCounts),
    );
    await sp.setInt(CustomerInsightsKeys.loyaltyPoints, insights.loyaltyPoints);
    await sp.setDouble(CustomerInsightsKeys.totalSavings, insights.totalSavings);
    await sp.setDouble(CustomerInsightsKeys.monthlySavings, insights.monthlySavings);
    await sp.setInt(CustomerInsightsKeys.ordersPlaced, insights.ordersPlaced);
    state = AsyncData(insights);
  }

  Future<void> trackProductView(String productId) async {
    final current = state.value ?? const CustomerInsights();
    final next = [
      productId,
      ...current.recentlyViewed.where((id) => id != productId),
    ].take(20).toList();
    await _persist(current.copyWith(recentlyViewed: next));
  }

  Future<void> recordPurchaseFromOrders(List<dynamic> orders) async {
    final current = state.value ?? const CustomerInsights();
    final counts = Map<String, int>.from(current.purchaseCounts);
    for (final order in orders) {
      final items = (order as Map)['items'] as List? ?? [];
      for (final item in items) {
        final id = (item as Map)['productId'] as String?;
        if (id != null) counts[id] = (counts[id] ?? 0) + ((item['quantity'] as int?) ?? 1);
      }
    }
    await _persist(current.copyWith(purchaseCounts: counts));
  }

  Future<void> recordOrderPlaced({double savings = 0}) async {
    final current = state.value ?? const CustomerInsights();
    await _persist(current.copyWith(
      ordersPlaced: current.ordersPlaced + 1,
      loyaltyPoints: current.loyaltyPoints + 10,
      totalSavings: current.totalSavings + savings,
      monthlySavings: current.monthlySavings + savings,
    ));
  }
}
