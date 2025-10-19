// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic widget test', (WidgetTester tester) async {
    // Build a simple app and verify it loads
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Test App'),
          ),
        ),
      ),
    );

    // Verify that the app loads correctly
    expect(find.text('Test App'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
