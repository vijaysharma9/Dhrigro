import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/storage_provider.dart';

class CustomerPrefsKeys {
  CustomerPrefsKeys._();
  static const onboardingDone = 'customer_onboarding_done';
  static const deliveryPincode = 'customer_delivery_pincode';
  static const deliveryLabel = 'customer_delivery_label';
  static const searchHistory = 'customer_search_history';
  static const welcomeCouponClaimed = 'customer_welcome_coupon_claimed';
}

class CustomerPrefs {
  const CustomerPrefs({
    this.onboardingDone = false,
    this.deliveryPincode,
    this.deliveryLabel,
    this.searchHistory = const [],
    this.welcomeCouponClaimed = false,
  });

  final bool onboardingDone;
  final String? deliveryPincode;
  final String? deliveryLabel;
  final List<String> searchHistory;
  final bool welcomeCouponClaimed;

  bool get hasLocation =>
      deliveryPincode != null && deliveryPincode!.length == 6;

  CustomerPrefs copyWith({
    bool? onboardingDone,
    String? deliveryPincode,
    String? deliveryLabel,
    List<String>? searchHistory,
    bool? welcomeCouponClaimed,
  }) {
    return CustomerPrefs(
      onboardingDone: onboardingDone ?? this.onboardingDone,
      deliveryPincode: deliveryPincode ?? this.deliveryPincode,
      deliveryLabel: deliveryLabel ?? this.deliveryLabel,
      searchHistory: searchHistory ?? this.searchHistory,
      welcomeCouponClaimed: welcomeCouponClaimed ?? this.welcomeCouponClaimed,
    );
  }
}

final customerPrefsProvider =
    AsyncNotifierProvider<CustomerPrefsNotifier, CustomerPrefs>(
  CustomerPrefsNotifier.new,
);

class CustomerPrefsNotifier extends AsyncNotifier<CustomerPrefs> {
  @override
  Future<CustomerPrefs> build() async {
    final prefs = await ref.watch(sharedPrefsProvider.future);
    final historyJson = prefs.getString(CustomerPrefsKeys.searchHistory);
    List<String> history = [];
    if (historyJson != null) {
      try {
        history = List<String>.from(jsonDecode(historyJson) as List);
      } catch (_) {}
    }
    return CustomerPrefs(
      onboardingDone: prefs.getBool(CustomerPrefsKeys.onboardingDone) ?? false,
      deliveryPincode: prefs.getString(CustomerPrefsKeys.deliveryPincode),
      deliveryLabel: prefs.getString(CustomerPrefsKeys.deliveryLabel),
      searchHistory: history,
      welcomeCouponClaimed:
          prefs.getBool(CustomerPrefsKeys.welcomeCouponClaimed) ?? false,
    );
  }

  Future<void> _persist(CustomerPrefs prefs) async {
    final sp = await ref.read(sharedPrefsProvider.future);
    await sp.setBool(CustomerPrefsKeys.onboardingDone, prefs.onboardingDone);
    if (prefs.deliveryPincode != null) {
      await sp.setString(CustomerPrefsKeys.deliveryPincode, prefs.deliveryPincode!);
    }
    if (prefs.deliveryLabel != null) {
      await sp.setString(CustomerPrefsKeys.deliveryLabel, prefs.deliveryLabel!);
    }
    await sp.setString(
      CustomerPrefsKeys.searchHistory,
      jsonEncode(prefs.searchHistory),
    );
    await sp.setBool(
      CustomerPrefsKeys.welcomeCouponClaimed,
      prefs.welcomeCouponClaimed,
    );
    state = AsyncData(prefs);
  }

  Future<void> completeOnboarding() async {
    final current = state.value ?? const CustomerPrefs();
    await _persist(current.copyWith(onboardingDone: true));
  }

  Future<void> setLocation({
    required String pincode,
    required String label,
  }) async {
    final current = state.value ?? const CustomerPrefs();
    await _persist(current.copyWith(
      deliveryPincode: pincode,
      deliveryLabel: label,
    ));
  }

  Future<void> addSearchTerm(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    final current = state.value ?? const CustomerPrefs();
    final next = [
      trimmed,
      ...current.searchHistory.where((s) => s != trimmed),
    ].take(10).toList();
    await _persist(current.copyWith(searchHistory: next));
  }

  Future<void> clearSearchHistory() async {
    final current = state.value ?? const CustomerPrefs();
    await _persist(current.copyWith(searchHistory: []));
  }

  Future<void> claimWelcomeCoupon() async {
    final current = state.value ?? const CustomerPrefs();
    await _persist(current.copyWith(welcomeCouponClaimed: true));
  }
}
