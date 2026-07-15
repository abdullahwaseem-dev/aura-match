import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_match/widgets/score_ring.dart';

void main() {
  testWidgets('ScoreRing reveal animation paints without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: ScoreRing(score: 87, label: 'ATS')),
        ),
      ),
    );

    // Step through the ~900ms reveal in small frames so _RingPainter.paint()
    // runs repeatedly across the full 0 -> score sweep, exactly as it does
    // during the live reveal that produced the reported assertion.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('87'), findsOneWidget);
  });

  testWidgets('ScoreRing handles score 0 and 100 boundaries', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: ScoreRing(score: 0))),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: ScoreRing(score: 100))),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
