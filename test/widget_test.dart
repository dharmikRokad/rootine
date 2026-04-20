// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habitz/app.dart';
import 'package:habitz/bootstrap.dart';

void main() {
  testWidgets('Habitz app renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [firebaseEnabledProvider.overrideWithValue(false)],
        child: const HabitzApp(),
      ),
    );

    expect(find.text('Habitz'), findsOneWidget);
    expect(find.text('Track'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
  });
}
