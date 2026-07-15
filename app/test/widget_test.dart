import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_match/main.dart';

void main() {
  testWidgets('App boots to the Aura Home tab', (WidgetTester tester) async {
    await tester.pumpWidget(const AuraMatchApp());
    await tester.pump();

    expect(find.text('AURA MATCH'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
  });
}
