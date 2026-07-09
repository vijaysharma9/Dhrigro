import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../core/admin/admin_api_utils.dart';
import '../../../../core/constants/app_strings.dart';
import 'invoice_print_stub.dart'
    if (dart.library.html) 'invoice_print_web.dart' as platform;

class OrderInvoicePrinter {
  OrderInvoicePrinter._();

  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  static final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static Future<void> printOrders(List<Map<String, dynamic>> orders) async {
    if (orders.isEmpty) return;
    if (!kIsWeb) {
      throw UnsupportedError('Invoice printing is only supported on web');
    }

    final title = orders.length == 1
        ? 'Invoice ${orders.first['orderNumber'] ?? ''}'
        : 'Dhrigro Invoices (${orders.length})';

    await platform.platformPrintHtml(
      buildInvoicesHtml(orders),
      title: title,
    );
  }

  static String buildInvoicesHtml(List<Map<String, dynamic>> orders) {
    final body = orders.map(_buildInvoiceSection).join('\n');
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Dhrigro Invoice</title>
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      color: #111827;
      margin: 0;
      padding: 24px;
      font-size: 13px;
      line-height: 1.45;
    }
    .invoice {
      max-width: 720px;
      margin: 0 auto 32px;
      page-break-after: always;
    }
    .invoice:last-child { page-break-after: auto; }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      border-bottom: 2px solid #16a34a;
      padding-bottom: 12px;
      margin-bottom: 16px;
    }
    .brand { font-size: 22px; font-weight: 700; color: #16a34a; }
    .tagline { font-size: 11px; color: #6b7280; margin-top: 2px; }
    .meta { text-align: right; font-size: 12px; }
    .meta strong { display: block; font-size: 15px; color: #111827; }
    .grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin-bottom: 16px;
    }
    .card {
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      padding: 12px;
      background: #fafafa;
    }
    .card h3 {
      margin: 0 0 8px;
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      color: #6b7280;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 12px 0;
    }
    th, td {
      border-bottom: 1px solid #e5e7eb;
      padding: 8px 6px;
      text-align: left;
      vertical-align: top;
    }
    th {
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 0.03em;
      color: #6b7280;
      background: #f9fafb;
    }
    td.num, th.num { text-align: right; }
    .totals {
      margin-left: auto;
      width: min(280px, 100%);
    }
    .totals .row {
      display: flex;
      justify-content: space-between;
      padding: 4px 0;
    }
    .totals .row.total {
      border-top: 2px solid #111827;
      margin-top: 6px;
      padding-top: 8px;
      font-size: 15px;
      font-weight: 700;
    }
    .chips { margin-top: 8px; }
    .chip {
      display: inline-block;
      border: 1px solid #d1d5db;
      border-radius: 999px;
      padding: 2px 8px;
      font-size: 11px;
      margin-right: 6px;
      margin-bottom: 4px;
    }
    .footer {
      margin-top: 20px;
      padding-top: 12px;
      border-top: 1px dashed #d1d5db;
      font-size: 11px;
      color: #6b7280;
      text-align: center;
    }
    @media print {
      body { padding: 0; }
      .invoice { margin-bottom: 0; }
    }
  </style>
</head>
<body>
$body
</body>
</html>
''';
  }

  static String _buildInvoiceSection(Map<String, dynamic> order) {
    final user = AdminApiUtils.asMapOrNull(order['user']);
    final address = AdminApiUtils.asMapOrNull(order['address']);
    final items = AdminApiUtils.asMapList(order['items']);
    final slot = AdminApiUtils.asMapOrNull(order['deliverySlot']);
    final placedAt = _formatDate(order['placedAt'] as String?);

    final subtotal = _money(order['subtotal']);
    final discount = _money(order['discountAmount']);
    final deliveryFee = _money(order['deliveryFee']);
    final sameDayFee = _money(order['sameDayFee']);
    final total = _money(order['totalAmount']);

    final itemRows = items.map((item) {
      final name = item['productName'] as String? ?? 'Item';
      final variant = item['variantLabel'] as String?;
      final label = variant != null && variant.isNotEmpty ? '$name ($variant)' : name;
      return '''
        <tr>
          <td>${_escape(label)}</td>
          <td class="num">${item['quantity'] ?? 0}</td>
          <td class="num">${_money(item['unitPrice'])}</td>
          <td class="num">${_money(item['totalPrice'])}</td>
        </tr>
      ''';
    }).join();

    final addressLines = <String>[];
    final line1 = address?['addressLine1'] ?? address?['line1'];
    final line2 = address?['addressLine2'] ?? address?['line2'];
    if (line1 != null && '$line1'.isNotEmpty) addressLines.add(_escape('$line1'));
    if (line2 != null && '$line2'.isNotEmpty) addressLines.add(_escape('$line2'));
    final cityPin = [
      address?['city'],
      address?['state'],
      address?['pincode'],
    ].where((v) => v != null && '$v'.isNotEmpty).join(', ');
    if (cityPin.isNotEmpty) addressLines.add(_escape(cityPin));

    return '''
<section class="invoice">
  <div class="header">
    <div>
      <div class="brand">${_escape(AppStrings.appName)}</div>
      <div class="tagline">${_escape(AppStrings.tagline)}</div>
    </div>
    <div class="meta">
      <strong>INVOICE</strong>
      <div>#${_escape(order['orderNumber'] as String? ?? '—')}</div>
      <div>$placedAt</div>
    </div>
  </div>

  <div class="grid">
    <div class="card">
      <h3>Bill to</h3>
      <div><strong>${_escape(user?['name'] as String? ?? 'Customer')}</strong></div>
      <div>${_escape(user?['phone'] as String? ?? '')}</div>
      ${user?['email'] != null ? '<div>${_escape(user!['email'] as String)}</div>' : ''}
      ${addressLines.isNotEmpty ? addressLines.map((l) => '<div>$l</div>').join() : '<div>—</div>'}
    </div>
    <div class="card">
      <h3>Order details</h3>
      <div>Status: <strong>${_escape((order['status'] as String? ?? '').replaceAll('_', ' '))}</strong></div>
      <div>Payment: ${_escape(order['paymentMethod'] as String? ?? '—')} (${_escape(order['paymentStatus'] as String? ?? '—')})</div>
      <div>Delivery: ${_escape((order['deliveryType'] as String? ?? 'STANDARD').replaceAll('_', ' '))}</div>
      ${slot != null ? '<div>Slot: ${_escape(slot['name'] as String? ?? slot['label'] as String? ?? '')}</div>' : ''}
    </div>
  </div>

  <table>
    <thead>
      <tr>
        <th>Item</th>
        <th class="num">Qty</th>
        <th class="num">Rate</th>
        <th class="num">Amount</th>
      </tr>
    </thead>
    <tbody>
      ${itemRows.isEmpty ? '<tr><td colspan="4">No items</td></tr>' : itemRows}
    </tbody>
  </table>

  <div class="totals">
    <div class="row"><span>Subtotal</span><span>$subtotal</span></div>
    ${discount != _currency.format(0) ? '<div class="row"><span>Discount</span><span>-$discount</span></div>' : ''}
    <div class="row"><span>Delivery fee</span><span>$deliveryFee</span></div>
    ${sameDayFee != _currency.format(0) ? '<div class="row"><span>Same-day fee</span><span>$sameDayFee</span></div>' : ''}
    <div class="row total"><span>Total</span><span>$total</span></div>
  </div>

  <div class="chips">
    <span class="chip">Order ID: ${_escape(order['id'] as String? ?? '')}</span>
    ${order['deliveryInstructions'] != null && '${order['deliveryInstructions']}'.isNotEmpty ? '<span class="chip">Note: ${_escape('${order['deliveryInstructions']}')}</span>' : ''}
  </div>

  <div class="footer">
    Thank you for shopping with ${_escape(AppStrings.appName)}.<br />
    For support, contact support@dhrigro.com
  </div>
</section>
''';
  }

  static String _money(dynamic value) => _currency.format(_toDouble(value));

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static String _formatDate(String? raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return _dateFormat.format(dt.toLocal());
  }

  static String _escape(String? input) {
    if (input == null) return '';
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
