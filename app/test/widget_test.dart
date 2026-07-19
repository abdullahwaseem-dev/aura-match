import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aura_match/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // supabase_flutter persists sessions via shared_preferences, whose
    // plugin channel isn't mocked by default in flutter_test.
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://fjpxajbctpwetfhahvlh.supabase.co',
      publishableKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZqcHhhamJjdHB3ZXRmaGFodmxoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM2NzY1NTcsImV4cCI6MjA5OTI1MjU1N30.dztDPgE0wa8becPnAvHbA9Go_6S-Rfg7s2Qm0mLo0Pw',
    );
  });

  testWidgets('Signed-out app shows the sign-in screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AuraMatchApp());
    await tester.pump();

    // No session exists in this test environment, so the auth gate shows
    // AuthScreen rather than the Home tab.
    expect(find.text('Welcome back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
