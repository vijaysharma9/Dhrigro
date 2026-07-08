import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('delivery placeholder smoke', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Delivery smoke'))),
    );
    expect(find.text('Delivery smoke'), findsOneWidget);
  });
}
