import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_match/widgets/aurora_button.dart';

void main() {
  testWidgets('Primary AuroraButton hover-then-unhover settles without throwing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AuroraButton(label: 'Continue', onPressed: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    // Hover in: boxShadow grows from 1 shadow to 2 (lift state).
    await gesture.moveTo(tester.getCenter(find.byType(AuroraButton)));
    await tester.pump();

    // Hover out: boxShadow shrinks back from 2 shadows to 1. This is the
    // transition that drove BoxShadow.lerpList's scale(1 - t) below zero
    // under the elastic overshoot curve before the fix.
    await gesture.moveTo(const Offset(0, 0));

    // Step through the whole elastic settle window in small frames, since
    // the overshoot/undershoot happens on specific intermediate frames, not
    // just at the end.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 10));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
