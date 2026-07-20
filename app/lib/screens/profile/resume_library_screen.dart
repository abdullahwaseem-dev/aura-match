import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/profile_models.dart';
import '../../state/navigation_state.dart';
import '../../state/resume_library_state.dart';
import '../../state/resume_state.dart';
import '../../theme/aurora.dart';
import '../../widgets/aura_orb.dart';
import '../../widgets/glass_container.dart';

class ResumeLibraryScreen extends StatefulWidget {
  const ResumeLibraryScreen({super.key});

  @override
  State<ResumeLibraryScreen> createState() => _ResumeLibraryScreenState();
}

class _ResumeLibraryScreenState extends State<ResumeLibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ResumeLibraryState>().load());
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<ResumeLibraryState>();

    return Scaffold(
      backgroundColor: AuroraColors.void_,
      appBar: AppBar(
        backgroundColor: AuroraColors.void_,
        elevation: 0,
        title: Text('Resume Library', style: AuroraText.displayM.copyWith(fontSize: 17)),
      ),
      body: SafeArea(child: _body(library)),
    );
  }

  Widget _body(ResumeLibraryState library) {
    if (library.loading && library.resumes.isEmpty) {
      return const Center(child: AuraOrb(size: 48));
    }
    if (library.resumes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AuroraSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open_outlined, size: 36, color: AuroraColors.mistDim),
              const SizedBox(height: AuroraSpacing.md),
              Text('Nothing saved yet', style: AuroraText.displayM, textAlign: TextAlign.center),
              const SizedBox(height: AuroraSpacing.sm),
              Text(
                'Score a resume in the Resume tab, then tap "Save to resume library" to keep a snapshot here.',
                style: AuroraText.body.copyWith(color: AuroraColors.mist),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      itemCount: library.resumes.length,
      itemBuilder: (context, i) => _ResumeRow(resume: library.resumes[i]),
    );
  }
}

class _ResumeRow extends StatefulWidget {
  const _ResumeRow({required this.resume});
  final SavedResume resume;

  @override
  State<_ResumeRow> createState() => _ResumeRowState();
}

class _ResumeRowState extends State<_ResumeRow> {
  bool _busy = false;

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final detail = await context.read<ResumeLibraryState>().fetch(widget.resume.id);
      if (!mounted) return;
      await context.read<ResumeState>().loadSaved(
            fileName: detail.fileName,
            resumeText: detail.resumeText,
            targetRole: detail.targetRole,
          );
      if (!mounted) return;
      context.read<NavigationState>().goTo(0); // Resume tab
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load: $e')));
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AuroraColors.void2,
        title: const Text('Delete this resume?', style: TextStyle(color: AuroraColors.ink)),
        content: Text('"${widget.resume.fileName}" will be removed from your library.', style: const TextStyle(color: AuroraColors.mist)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete', style: TextStyle(color: AuroraColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<ResumeLibraryState>().delete(widget.resume.id);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resume;
    return Padding(
      padding: const EdgeInsets.only(bottom: AuroraSpacing.md),
      child: GlassContainer(
        interactive: true,
        onTap: _busy ? null : _load,
        child: Row(
          children: [
            if (r.atsScore != null) ...[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AuroraColors.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AuroraRadius.pill),
                ),
                child: Text('${r.atsScore}', style: AuroraText.mono.copyWith(fontSize: 13, color: AuroraColors.cyanSoft)),
              ),
              const SizedBox(width: AuroraSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.fileName, style: AuroraText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(r.targetRole, style: AuroraText.bodySm, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (_busy)
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AuroraColors.cyan))
            else
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AuroraColors.mistDim),
                onPressed: _delete,
              ),
          ],
        ),
      ),
    );
  }
}
