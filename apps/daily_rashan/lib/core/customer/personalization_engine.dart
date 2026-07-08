/// Client-side personalization — no backend changes.
class PersonalizationEngine {
  PersonalizationEngine._();

  static List<Map<String, dynamic>> allCatalogProducts(
    Map<String, dynamic> homeData,
  ) {
    final seen = <String>{};
    final list = <Map<String, dynamic>>[];
    for (final key in [
      'featuredProducts',
      'bestSellers',
      'trendingProducts',
    ]) {
      for (final p in (homeData[key] as List? ?? [])) {
        final product = Map<String, dynamic>.from(p as Map);
        final id = product['id'] as String?;
        if (id != null && seen.add(id)) list.add(product);
      }
    }
    return list;
  }

  static List<Map<String, dynamic>> recommendedForYou({
    required Map<String, dynamic> homeData,
    required Map<String, int> purchaseCounts,
    required List<String> searchHistory,
  }) {
    final catalog = allCatalogProducts(homeData);
    if (catalog.isEmpty) return [];

    final scored = catalog.map((p) {
      final id = p['id'] as String;
      var score = 0.0;
      score += (purchaseCounts[id] ?? 0) * 3;
      if (p['isBestSeller'] == true) score += 2;
      if (p['isTrending'] == true) score += 1.5;
      if (p['discountPrice'] != null) score += 1;
      final name = (p['name'] as String? ?? '').toLowerCase();
      for (final term in searchHistory) {
        if (name.contains(term.toLowerCase())) score += 2;
      }
      return (product: p, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(10).map((e) => e.product).toList();
  }

  static List<Map<String, dynamic>> basedOnYourPurchases({
    required List<dynamic> orders,
    required Map<String, dynamic> homeData,
  }) {
    final catalog = allCatalogProducts(homeData);
    final catalogById = {for (final p in catalog) p['id'] as String: p};
    final freq = <String, int>{};

    for (final order in orders) {
      for (final item in ((order as Map)['items'] as List? ?? [])) {
        final id = (item as Map)['productId'] as String?;
        if (id != null) {
          freq[id] = (freq[id] ?? 0) + ((item['quantity'] as int?) ?? 1);
        }
      }
    }

    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .map((e) => catalogById[e.key])
        .whereType<Map<String, dynamic>>()
        .take(10)
        .toList();
  }

  static List<Map<String, dynamic>> popularInYourArea(
    Map<String, dynamic> homeData,
  ) {
    final best = (homeData['bestSellers'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final trending = (homeData['trendingProducts'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final p in [...best, ...trending]) {
      final id = p['id'] as String?;
      if (id != null && seen.add(id)) result.add(p);
    }
    return result.take(10).toList();
  }

  static List<Map<String, dynamic>> recentlyViewedProducts({
    required List<String> viewedIds,
    required Map<String, dynamic> homeData,
  }) {
    if (viewedIds.isEmpty) return [];
    final catalog = allCatalogProducts(homeData);
    final byId = {for (final p in catalog) p['id'] as String: p};
    return viewedIds
        .map((id) => byId[id])
        .whereType<Map<String, dynamic>>()
        .take(10)
        .toList();
  }
}
