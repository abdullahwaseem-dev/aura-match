import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../state/profile_state.dart';
import '../../theme/aurora.dart';
import '../../widgets/aurora_button.dart';
import '../../widgets/glass_container.dart';
import 'resume_library_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _exporting = false;
  bool _deletingData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProfileState>().load());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final profile = context.watch<ProfileState>();
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

            const SizedBox(height: AuroraSpacing.xl),
            Text('RESUME', style: AuroraText.caption.copyWith(color: AuroraColors.mist)),
            const SizedBox(height: AuroraSpacing.sm),
            GlassContainer(
              interactive: true,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResumeLibraryScreen())),
              child: Row(
                children: [
                  const Icon(Icons.folder_open_outlined, size: 20, color: AuroraColors.cyanSoft),
                  const SizedBox(width: AuroraSpacing.md),
                  Expanded(
                    child: Text('Resume library', style: AuroraText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: AuroraColors.mistDim),
                ],
              ),
            ),

            const SizedBox(height: AuroraSpacing.xl),
            Text('JOB MATCHING', style: AuroraText.caption.copyWith(color: AuroraColors.mist)),
            const SizedBox(height: AuroraSpacing.sm),
            GlassContainer(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Auto-draft high matches', style: AuroraText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          'When a new job scores 80+ in your feed, Aura drafts a tailored resume for it automatically — you still review and apply yourself, nothing is ever auto-submitted.',
                          style: AuroraText.bodySm,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AuroraSpacing.md),
                  Switch(
                    value: profile.autoDraftEnabled,
                    activeTrackColor: AuroraColors.cyan,
                    onChanged: profile.loading ? null : (v) => context.read<ProfileState>().setAutoDraftEnabled(v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AuroraSpacing.xl),
            Text('PRIVACY', style: AuroraText.caption.copyWith(color: AuroraColors.mist)),
            const SizedBox(height: AuroraSpacing.sm),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuroraButton(
                    label: _exporting ? 'Preparing export…' : 'Export my data',
                    variant: AuroraButtonVariant.secondary,
                    expand: true,
                    onPressed: _exporting ? null : _exportData,
                  ),
                  const SizedBox(height: AuroraSpacing.md),
                  AuroraButton(
                    label: _deletingData ? 'Deleting…' : 'Delete all my data',
                    variant: AuroraButtonVariant.danger,
                    expand: true,
                    onPressed: _deletingData ? null : _deleteData,
                  ),
                  const SizedBox(height: AuroraSpacing.sm),
                  Text(
                    'Erases your resumes, job matches, and applications. This does not delete your login itself — contact us for full account removal.',
                    style: AuroraText.bodySm.copyWith(fontSize: 11, color: AuroraColors.mistDim),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AuroraSpacing.xl),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('More coming here', style: AuroraText.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AuroraSpacing.sm),
                  Text('Plan & billing ships in a later phase.', style: AuroraText.bodySm),
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

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      final data = await context.read<ProfileState>().exportData();
      final pretty = const JsonEncoder.withIndent('  ').convert(data);
      if (mounted) await _showExportSheet(pretty);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not export: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _showExportSheet(String json) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AuroraColors.void2,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AuroraRadius.sheet)),
            border: Border(top: BorderSide(color: AuroraColors.line)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    Expanded(child: Text('Your data', style: AuroraText.displayM.copyWith(fontSize: 17))),
                    AuroraButton(
                      label: 'Copy JSON',
                      icon: Icons.copy_outlined,
                      variant: AuroraButtonVariant.secondary,
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: json));
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: SelectableText(json, style: AuroraText.mono.copyWith(fontSize: 11, color: AuroraColors.mist)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AuroraColors.void2,
        title: const Text('Delete all your data?', style: TextStyle(color: AuroraColors.ink)),
        content: const Text(
          'This permanently erases every resume, job match, and application tied to your account. This cannot be undone.',
          style: TextStyle(color: AuroraColors.mist),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete everything', style: TextStyle(color: AuroraColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingData = true);
    try {
      await context.read<ProfileState>().deleteAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All your data has been deleted.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete data: $e')));
    } finally {
      if (mounted) setState(() => _deletingData = false);
    }
  }
}
