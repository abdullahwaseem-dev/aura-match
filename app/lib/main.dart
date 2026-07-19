import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_client.dart';
import 'shell/app_shell.dart';
import 'state/interview_state.dart';
import 'state/jobs_state.dart';
import 'state/navigation_state.dart';
import 'state/resume_state.dart';
import 'theme/aurora.dart';

void main() {
  runApp(const AuraMatchApp());
}

class AuraMatchApp extends StatelessWidget {
  const AuraMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        ChangeNotifierProvider<ResumeState>(
          create: (context) => ResumeState(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<JobsState>(
          create: (context) => JobsState(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<InterviewState>(
          create: (context) => InterviewState(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<NavigationState>(create: (_) => NavigationState()),
      ],
      child: MaterialApp(
        title: 'AURA MATCH',
        debugShowCheckedModeBanner: false,
        theme: buildAuroraTheme(),
        home: const AppShell(),
      ),
    );
  }
}
