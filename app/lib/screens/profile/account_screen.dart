import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../theme/aurora.dart';
import '../../widgets/aurora_button.dart';
import '../../widgets/glass_container.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final email = auth.user?.email ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PROFILE', style: AuroraText.caption.copyWith(color: AuroraColors.violetSoft)),
            const SizedBox(height: AuroraSpacing.sm),
            Text('Account', style: AuroraText.displayM),
            const SizedBox(height: AuroraSpacing.lg),
            GlassContainer(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AuroraColors.cyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AuroraRadius.pill),
                    ),
                    child: Text(
                      email.isNotEmpty ? email[0].toUpperCase() : '?',
                      style: AuroraText.body.copyWith(fontWeight: FontWeight.w800, color: AuroraColors.cyanSoft),
                    ),
                  ),
                  const SizedBox(width: AuroraSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(email, style: AuroraText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 14.5)),
                        const SizedBox(height: 2),
                        Text('Signed in', style: AuroraText.bodySm.copyWith(color: AuroraColors.success)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AuroraSpacing.lg),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('More coming here', style: AuroraText.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AuroraSpacing.sm),
                  Text(
                    'Resume library, plan & billing, privacy controls, and the auto-apply master switch ship in a later phase.',
                    style: AuroraText.bodySm,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AuroraSpacing.xl),
            AuroraButton(
              label: 'Sign out',
              variant: AuroraButtonVariant.danger,
              expand: true,
              onPressed: () => context.read<AuthState>().signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
