// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nestly/core/theme/app_theme.dart';
import 'package:nestly/core/widgets/neu/neu_button.dart';

void main() {
  testWidgets('NeuButton renders its label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NeuButton(label: 'Sign in', onPressed: () {}),
        ),
      ),
    );

    expect(find.text('Sign in'), findsOneWidget);
  });
}
