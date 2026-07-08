class ProductFormatters {
  ProductFormatters._();

  static String? imageUrl(Map<String, dynamic> product) {
    final productImages = product['productImages'] as List?;
    if (productImages?.isNotEmpty == true) {
      final first = productImages!.first as Map<String, dynamic>;
      return (first['thumbnailUrl'] ?? first['imageUrl']) as String?;
    }
    final images = product['images'] as List?;
    if (images?.isNotEmpty == true) return images!.first as String;
    return null;
  }

  static double price(Map<String, dynamic> product) {
    final discount = product['discountPrice'];
    if (discount != null) return _num(discount);
    return _num(product['basePrice']);
  }

  static double basePrice(Map<String, dynamic> product) => _num(product['basePrice']);

  static int? discountPercent(Map<String, dynamic> product) {
    final base = basePrice(product);
    final discount = product['discountPrice'];
    if (discount == null || base <= 0) return null;
    final d = _num(discount);
    if (d >= base) return null;
    return ((1 - d / base) * 100).round();
  }

  static double rating(Map<String, dynamic> product) {
    final reviews = product['reviews'] as List?;
    if (reviews != null && reviews.isNotEmpty) {
      var sum = 0.0;
      for (final r in reviews) {
        sum += _num((r as Map)['rating']);
      }
      return sum / reviews.length;
    }
    return _num(product['avgRating'] ?? 4.2);
  }

  static int stock(Map<String, dynamic> product) {
    final s = product['stock'];
    if (s is int) return s;
    return int.tryParse('$s') ?? 0;
  }

  static bool inStock(Map<String, dynamic> product) => stock(product) > 0;

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}
