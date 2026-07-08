import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dhrigro/core/constants/app_colors.dart';

void main() {
  testWidgets('admin theme smoke', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(primaryColor: AppColors.primaryGreen),
        home: const Scaffold(body: Text('Admin smoke')),
      ),
    );
    expect(find.text('Admin smoke'), findsOneWidget);
  });
}
