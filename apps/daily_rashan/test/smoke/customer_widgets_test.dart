import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dhrigro/shared/widgets/empty_state_widget.dart';
import 'package:dhrigro/shared/widgets/skeleton_loader.dart';

/// Customer UI smoke — runs in CI without a device target.
void main() {
  group('Customer UI smoke', () {
    testWidgets('empty state renders CTA', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.shopping_cart_outlined,
              title: 'Cart is empty',
              actionLabel: 'Browse products',
              onAction: () {},
            ),
          ),
        ),
      );
      expect(find.text('Cart is empty'), findsOneWidget);
      expect(find.text('Browse products'), findsOneWidget);
    });

    testWidgets('home skeleton renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomeSkeleton())),
      );
      expect(find.byType(HomeSkeleton), findsOneWidget);
    });
  });
}
