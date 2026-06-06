// Widget test for the onboarding flow. This exercises the widget layer of the
// app (rendering, page content, navigation controls) without requiring
// Firebase, so it runs reliably in CI / on any machine.
//
// Run with:  flutter test test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sptm/screens/onboarding/onboarding_screen.dart';

void main() {
  setUp(() {
    // The onboarding screen reads/writes SharedPreferences when finishing;
    // provide an in-memory mock so the widget tree builds without a platform.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Onboarding shows the first slide and navigation controls',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    // Advance past the one-shot entrance animations.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // First slide content from the proposal's feature set.
    expect(find.text('Manage Your Tasks'), findsOneWidget);

    // Navigation affordances are present.
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next →'), findsOneWidget);
  });

  testWidgets('Tapping Next advances to the second onboarding slide',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Next →'));
    // Page-change animation is 380ms; pump well past it.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Never Miss a Deadline'), findsOneWidget);
  });
}
