// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rootine/app.dart';
import 'package:rootine/core/theme_providers.dart';
import 'package:rootine/features/auth/presentation/auth_gate_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Rootine app renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RootineApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(AuthGatePage), findsOneWidget);
  });
}
