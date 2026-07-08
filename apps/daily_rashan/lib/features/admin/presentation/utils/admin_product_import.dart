import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

/// CSV / Excel import helpers for admin product bulk upload.
class AdminProductImport {
  AdminProductImport._();

  static const templateCsv =
      'name,category,subcategory,basePrice,discountPrice,stock,unit,sku,description,imageUrl,isFeatured,isActive\n'
      'Sample Product,Fruits & Vegetables,Vegetables,99,89,50,kg,SKU-001,Optional description,https://example.com/image.jpg,false,true';

  static Future<List<Map<String, dynamic>>> parseFile(PlatformFile file) async {
    final name = file.name.toLowerCase();
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw FormatException('Could not read "${file.name}"');
    }

    if (name.endsWith('.xlsx') || name.endsWith('.xls')) {
      return _parseExcel(bytes);
    }
    if (name.endsWith('.csv')) {
      return _parseCsv(utf8.decode(bytes));
    }
    throw FormatException('Unsupported file type. Use .csv or .xlsx');
  }

  static List<Map<String, dynamic>> _parseCsv(String text) {
    final table = _parseCsvRows(text);
    if (table.length < 2) {
      throw FormatException('CSV must include a header row and at least one product');
    }
    return _rowsFromTable(table);
  }

  static List<Map<String, dynamic>> _parseExcel(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw FormatException('Excel file has no sheets');
    }

    final sheet = excel.tables.values.first;
    if (sheet.maxRows < 2) {
      throw const FormatException(
        'Excel sheet must include a header row and at least one product',
      );
    }

    final table = <List<String>>[];
    for (var rowIndex = 0; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.row(rowIndex);
      final values = row.map((cell) => _cellToString(cell?.value)).toList();
      if (values.every((v) => v.isEmpty)) continue;
      table.add(values);
    }

    return _rowsFromTable(table);
  }

  static List<Map<String, dynamic>> _rowsFromTable(List<List<String>> table) {
    final headers = table.first.map(_normalizeHeader).toList();
    final rows = <Map<String, dynamic>>[];

    for (var i = 1; i < table.length; i++) {
      final cells = table[i];
      final raw = <String, String>{};
      for (var col = 0; col < headers.length; col++) {
        raw[headers[col]] = col < cells.length ? cells[col].trim() : '';
      }

      final name = _pick(raw, ['name', 'product', 'product_name']);
      if (name.isEmpty) continue;

      final row = <String, dynamic>{
        'name': name,
        'basePrice': _parseDouble(_pick(raw, ['baseprice', 'base_price', 'price'])),
      };

      final categoryId = _pick(raw, ['categoryid', 'category_id']);
      final category = _pick(raw, ['category', 'category_name']);
      if (categoryId.isNotEmpty) row['categoryId'] = categoryId;
      if (category.isNotEmpty) row['category'] = category;

      final subcategory = _pick(raw, ['subcategory', 'sub_category']);
      if (subcategory.isNotEmpty) row['subcategory'] = subcategory;

      final discount = _pick(raw, ['discountprice', 'discount_price']);
      if (discount.isNotEmpty) row['discountPrice'] = _parseDouble(discount);

      final stock = _pick(raw, ['stock', 'qty', 'quantity']);
      if (stock.isNotEmpty) row['stock'] = _parseInt(stock);

      final unit = _pick(raw, ['unit']);
      if (unit.isNotEmpty) row['unit'] = unit;

      final sku = _pick(raw, ['sku', 'product_sku']);
      if (sku.isNotEmpty) row['sku'] = sku;

      final description = _pick(raw, ['description', 'desc']);
      if (description.isNotEmpty) row['description'] = description;

      final imageUrl = _pick(raw, ['imageurl', 'image_url', 'image', 'images']);
      if (imageUrl.isNotEmpty) row['imageUrl'] = imageUrl;

      final featured = _pick(raw, ['isfeatured', 'is_featured', 'featured']);
      if (featured.isNotEmpty) row['isFeatured'] = _parseBool(featured);

      final active = _pick(raw, ['isactive', 'is_active', 'active']);
      if (active.isNotEmpty) row['isActive'] = _parseBool(active);

      if (row['basePrice'] == null) {
        throw FormatException('Row ${i + 1}: basePrice is required for "$name"');
      }

      rows.add(row);
    }

    if (rows.isEmpty) {
      throw FormatException('No valid product rows found in file');
    }
    return rows;
  }

  static String _normalizeHeader(String header) {
    return header.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  static String _pick(Map<String, String> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  static String _cellToString(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return value.toIso8601String();
    return value.toString().trim();
  }

  static double? _parseDouble(String value) {
    final cleaned = value.replaceAll(RegExp(r'[₹,\s]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static int? _parseInt(String value) {
    final cleaned = value.replaceAll(RegExp(r'[,\s]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  static bool _parseBool(String value) {
    final v = value.trim().toLowerCase();
    return v == 'true' || v == '1' || v == 'yes' || v == 'y';
  }

  static List<List<String>> _parseCsvRows(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    var cell = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      final next = i + 1 < text.length ? text[i + 1] : '';

      if (inQuotes) {
        if (char == '"' && next == '"') {
          cell.write('"');
          i++;
        } else if (char == '"') {
          inQuotes = false;
        } else {
          cell.write(char);
        }
        continue;
      }

      if (char == '"') {
        inQuotes = true;
      } else if (char == ',') {
        row.add(cell.toString());
        cell = StringBuffer();
      } else if (char == '\n' || (char == '\r' && next == '\n')) {
        row.add(cell.toString());
        if (row.any((value) => value.isNotEmpty)) rows.add(row);
        row = [];
        cell = StringBuffer();
        if (char == '\r') i++;
      } else if (char != '\r') {
        cell.write(char);
      }
    }

    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }

    return rows;
  }
}
