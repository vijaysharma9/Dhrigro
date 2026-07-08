import 'package:dio/dio.dart';

/// Ensures the customer has a delivery address in the API after location setup.
Future<void> syncDeliveryAddress({
  required Dio dio,
  required String pincode,
  required String label,
  required String addressLine1,
  required String fullName,
  required String phone,
  String? city,
}) async {
  final resolvedCity =
      (city?.trim().isNotEmpty ?? false) ? city!.trim() : 'Metro City';
  const state = 'Delhi';

  final listRes = await dio.get('/addresses');
  final listData = listRes.data;
  final existing = listData is List
      ? listData
      : (listData as Map?)?['data'] as List? ?? [];

  Map<String, dynamic>? match;
  for (final item in existing) {
    final addr = item as Map<String, dynamic>;
    if (addr['pincode'] == pincode) {
      match = addr;
      break;
    }
  }

  final payload = {
    'label': label,
    'fullName': fullName,
    'phone': phone,
    'addressLine1': addressLine1,
    'city': resolvedCity,
    'state': state,
    'pincode': pincode,
    'isDefault': true,
  };

  if (match != null) {
    await dio.patch('/addresses/${match['id']}', data: payload);
  } else {
    await dio.post('/addresses', data: payload);
  }
}
