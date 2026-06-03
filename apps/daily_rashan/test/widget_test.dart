import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_rashan/shared/widgets/shimmer_box.dart';

void main() {
  testWidgets('ShimmerBox renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ShimmerBox(width: 100, height: 20))),
    );
    expect(find.byType(ShimmerBox), findsOneWidget);
  });
}
