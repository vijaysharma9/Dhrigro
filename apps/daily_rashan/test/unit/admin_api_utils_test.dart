import 'package:dhrigro/core/admin/admin_api_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('asMap deep-converts LinkedHashMap-style nested maps', () {
    final raw = <dynamic, dynamic>{
      'data': [
        <dynamic, dynamic>{
          'id': '1',
          'orderNumber': 'DR-1',
          'user': <dynamic, dynamic>{
            'name': 'Demo',
            'phone': '9876543210',
          },
          'assignment': null,
        },
      ],
      'meta': <dynamic, dynamic>{'page': 1, 'total': 1},
    };

    final parsed = AdminApiUtils.asMap(raw);
    final rows = AdminApiUtils.asMapList(parsed['data']);
    final user = AdminApiUtils.asMapOrNull(rows.first['user']);

    expect(user, isNotNull);
    expect(user!['name'], 'Demo');
    expect(() => user as Map<String, dynamic>, returnsNormally);
  });
}
