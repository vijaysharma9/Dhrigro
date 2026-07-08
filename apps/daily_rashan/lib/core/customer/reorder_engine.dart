class ReorderItem {
  const ReorderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unitPrice,
    this.product,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double? unitPrice;
  final Map<String, dynamic>? product;

  Map<String, dynamic> toProductMap() {
    return product ??
        {
          'id': productId,
          'name': productName,
          'basePrice': unitPrice ?? 0,
          'unit': 'piece',
        };
  }
}

class ReorderBundle {
  const ReorderBundle({
    required this.orderId,
    required this.orderNumber,
    required this.items,
    required this.placedAt,
  });

  final String orderId;
  final String orderNumber;
  final List<ReorderItem> items;
  final DateTime? placedAt;
}

class ReorderEngine {
  ReorderEngine._();

  static List<ReorderItem> extractFrequentProducts(List<dynamic> orders) {
    final freq = <String, ReorderItem>{};
    for (final order in orders) {
      for (final raw in ((order as Map)['items'] as List? ?? [])) {
        final item = raw as Map<String, dynamic>;
        final id = item['productId'] as String? ??
            (item['product'] as Map?)?['id'] as String?;
        if (id == null) continue;
        final qty = item['quantity'] as int? ?? 1;
        final existing = freq[id];
        freq[id] = ReorderItem(
          productId: id,
          productName: item['productName'] as String? ??
              (item['product'] as Map?)?['name'] as String? ??
              'Product',
          quantity: (existing?.quantity ?? 0) + qty,
          unitPrice: _num(item['unitPrice']),
          product: item['product'] as Map<String, dynamic>?,
        );
      }
    }
    final list = freq.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    return list.take(12).toList();
  }

  static ReorderBundle? lastOrderBundle(List<dynamic> orders) {
    if (orders.isEmpty) return null;
    final order = orders.first as Map<String, dynamic>;
    final items = <ReorderItem>[];
    for (final raw in (order['items'] as List? ?? [])) {
      final item = raw as Map<String, dynamic>;
      final id = item['productId'] as String?;
      if (id == null) continue;
      items.add(ReorderItem(
        productId: id,
        productName: item['productName'] as String? ?? 'Product',
        quantity: item['quantity'] as int? ?? 1,
        unitPrice: _num(item['unitPrice']),
        product: item['product'] as Map<String, dynamic>?,
      ));
    }
    if (items.isEmpty) return null;
    return ReorderBundle(
      orderId: order['id'] as String,
      orderNumber: order['orderNumber'] as String? ?? '',
      items: items,
      placedAt: DateTime.tryParse(order['placedAt'] as String? ?? ''),
    );
  }

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}
