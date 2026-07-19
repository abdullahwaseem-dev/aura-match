import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

enum AuthStatus { unknown, signedOut, needsEmailConfirmation, signedIn }

/// Thin wrapper around Supabase Auth (email + password). Reacts to
/// [sb.SupabaseClient.auth]'s own auth-state stream, so a session restored
/// from local storage on app start, a real sign-in, or a sign-out all flow
/// through the same [status] the UI watches.
class AuthState extends ChangeNotifier {
  AuthState() {
    _sub = _auth.onAuthStateChange.listen((_) => _sync());
    _sync();
  }

  final sb.GoTrueClient _auth = sb.Supabase.instance.client.auth;
  late final StreamSubscription<sb.AuthState> _sub;

  AuthStatus status = AuthStatus.unknown;
  bool loading = false;
  String? error;

  sb.User? get user => _auth.currentUser;
  String? get accessToken => _auth.currentSession?.accessToken;

  void _sync() {
    status = _auth.currentSession != null ? AuthStatus.signedIn : AuthStatus.signedOut;
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _auth.signInWithPassword(email: email, password: password);
      // onAuthStateChange fires _sync(); nothing else to do here.
    } on sb.AuthException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Could not sign in: $e';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> signUp({required String email, required String password}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _auth.signUp(email: email, password: password);
      // If the project requires email confirmation, signUp succeeds but
      // returns no session — the user must click the emailed link first.
      status = res.session != null ? AuthStatus.signedIn : AuthStatus.needsEmailConfirmation;
    } on sb.AuthException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Could not create your account: $e';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // onAuthStateChange fires _sync().
  }

  /// Returns from the "check your email" screen to the sign-in form —
  /// there's no session to sign out of yet, just a local status to reset.
  void backToSignIn() {
    status = AuthStatus.signedOut;
    error = null;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
