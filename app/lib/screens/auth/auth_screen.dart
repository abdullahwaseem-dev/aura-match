import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../theme/aurora.dart';
import '../../widgets/aura_orb.dart';
import '../../widgets/aurora_button.dart';
import '../../widgets/glass_container.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    final auth = context.read<AuthState>();
    if (_isSignUp) {
      auth.signUp(email: email, password: password);
    } else {
      auth.signIn(email: email, password: password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (auth.status == AuthStatus.needsEmailConfirmation) {
      return _ConfirmEmailView(
        email: _emailController.text.trim(),
        onBack: () => context.read<AuthState>().backToSignIn(),
      );
    }

    return Scaffold(
      backgroundColor: AuroraColors.void_,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AuroraSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AuraOrb(size: 68)),
                  const SizedBox(height: AuroraSpacing.lg),
                  Text('AURA MATCH', style: AuroraText.caption.copyWith(color: AuroraColors.violetSoft), textAlign: TextAlign.center),
                  const SizedBox(height: AuroraSpacing.sm),
                  Text(
                    _isSignUp ? 'Create your account' : 'Welcome back',
                    style: AuroraText.displayM,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AuroraSpacing.xl),
                  GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _field(
                          controller: _emailController,
                          hint: 'Email',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AuroraSpacing.smd),
                        _field(
                          controller: _passwordController,
                          hint: 'Password',
                          icon: Icons.lock_outline,
                          obscure: _obscure,
                          suffix: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: AuroraColors.mistDim),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                      ],
                    ),
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: AuroraSpacing.md),
                    Text(auth.error!, style: AuroraText.bodySm.copyWith(color: AuroraColors.danger), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: AuroraSpacing.lg),
                  AuroraButton(
                    label: auth.loading ? 'Please wait…' : (_isSignUp ? 'Create account' : 'Sign in'),
                    expand: true,
                    onPressed: auth.loading ? null : _submit,
                  ),
                  const SizedBox(height: AuroraSpacing.md),
                  AuroraButton(
                    label: _isSignUp ? 'Have an account? Sign in' : 'New here? Create an account',
                    variant: AuroraButtonVariant.ghost,
                    expand: true,
                    onPressed: auth.loading
                        ? null
                        : () {
                            context.read<AuthState>().clearError();
                            setState(() => _isSignUp = !_isSignUp);
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: AuroraText.body,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AuroraText.body.copyWith(color: AuroraColors.mistDim),
        prefixIcon: Icon(icon, size: 18, color: AuroraColors.mistDim),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuroraRadius.control),
          borderSide: const BorderSide(color: AuroraColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuroraRadius.control),
          borderSide: const BorderSide(color: AuroraColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuroraRadius.control),
          borderSide: const BorderSide(color: AuroraColors.cyan, width: 1.5),
        ),
      ),
    );
  }
}

class _ConfirmEmailView extends StatelessWidget {
  const _ConfirmEmailView({required this.email, required this.onBack});
  final String email;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuroraColors.void_,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AuroraSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 40, color: AuroraColors.cyanSoft),
                const SizedBox(height: AuroraSpacing.lg),
                Text('Check your email', style: AuroraText.displayM, textAlign: TextAlign.center),
                const SizedBox(height: AuroraSpacing.sm),
                Text(
                  email.isEmpty
                      ? "We've sent a confirmation link to your inbox — click it, then come back and sign in."
                      : "We've sent a confirmation link to $email — click it, then come back and sign in.",
                  style: AuroraText.body.copyWith(color: AuroraColors.mist),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AuroraSpacing.xl),
                AuroraButton(label: 'Back to sign in', variant: AuroraButtonVariant.secondary, onPressed: onBack),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
