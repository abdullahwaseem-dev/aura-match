import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Hide gotrue's AuthState (an auth-change-event type) — this app's own
// ChangeNotifier of the same name (state/auth_state.dart) is what's used here.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'screens/auth/auth_screen.dart';
import 'services/api_client.dart';
import 'shell/app_shell.dart';
import 'state/auth_state.dart';
import 'state/interview_state.dart';
import 'state/jobs_state.dart';
import 'state/navigation_state.dart';
import 'state/resume_state.dart';
import 'theme/aurora.dart';

// The anon/publishable key is designed to be public — it ships inside every
// Supabase client app and is safe in source control; access control is
// enforced by RLS policies on the server, not by keeping this secret.
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://fjpxajbctpwetfhahvlh.supabase.co');
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZqcHhhamJjdHB3ZXRmaGFodmxoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM2NzY1NTcsImV4cCI6MjA5OTI1MjU1N30.dztDPgE0wa8becPnAvHbA9Go_6S-Rfg7s2Qm0mLo0Pw',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseAnonKey);
  runApp(const AuraMatchApp());
}

class AuraMatchApp extends StatelessWidget {
  const AuraMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        ChangeNotifierProvider<AuthState>(create: (_) => AuthState()),
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
        home: const _AuthGate(),
      ),
    );
  }
}

/// Shows the sign-in/sign-up flow until a session exists, then the app.
/// Also clears every other provider's in-memory state on sign-out — without
/// this, a second user signing in on the same device would see the first
/// user's resume, job matches, and interview transcript until fresh data
/// happened to overwrite it.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  AuthStatus? _previousStatus;

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthState>().status;
    if (_previousStatus == AuthStatus.signedIn && status != AuthStatus.signedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ResumeState>().reset();
        context.read<JobsState>().clear();
        context.read<InterviewState>().reset();
        context.read<NavigationState>().goTo(1);
      });
    }
    _previousStatus = status;
    if (status == AuthStatus.signedIn) return const AppShell();
    return const AuthScreen();
  }
}
