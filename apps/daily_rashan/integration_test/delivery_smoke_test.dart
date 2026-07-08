import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('delivery shell placeholder smoke', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Delivery smoke'))),
    );
    expect(find.text('Delivery smoke'), findsOneWidget);
  });
}
