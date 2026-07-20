import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:aura_match/screens/jobs/custom_job_screen.dart';
import 'package:aura_match/services/api_client.dart';
import 'package:aura_match/state/jobs_state.dart';
import 'package:aura_match/state/resume_state.dart';

void main() {
  testWidgets('Custom Job screen prompts for a resume scan when none exists', (tester) async {
    final api = ApiClient();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ResumeState>(create: (_) => ResumeState(api)),
          ChangeNotifierProvider<JobsState>(create: (_) => JobsState(api)),
        ],
        child: const MaterialApp(home: CustomJobScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Scan a resume first'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
