import 'dart:convert';
import 'dart:typed_data';

import 'package:dhrigro/features/admin/presentation/utils/admin_product_import.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses CSV rows into import payload', () async {
    const csv = '''
name,category,basePrice,stock
Bananas,Fruits & Vegetables,49,100
''';

    final rows = await AdminProductImport.parseFile(
      PlatformFile(
        name: 'products.csv',
        size: csv.length,
        bytes: Uint8List.fromList(utf8.encode(csv)),
      ),
    );

    expect(rows, hasLength(1));
    expect(rows.first['name'], 'Bananas');
    expect(rows.first['category'], 'Fruits & Vegetables');
    expect(rows.first['basePrice'], 49.0);
    expect(rows.first['stock'], 100);
  });
}
