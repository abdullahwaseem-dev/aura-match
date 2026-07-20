import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/jobs_state.dart';
import '../../state/resume_state.dart';
import '../../theme/aurora.dart';
import '../../widgets/aurora_button.dart';
import '../../widgets/glass_container.dart';
import 'widgets/draft_review_sheet.dart';

class CustomJobScreen extends StatefulWidget {
  const CustomJobScreen({super.key});

  @override
  State<CustomJobScreen> createState() => _CustomJobScreenState();
}

class _CustomJobScreenState extends State<CustomJobScreen> {
  final _promptController = TextEditingController();
  PlatformFile? _image;
  PlatformFile? _pdf;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _image != null || _pdf != null || _promptController.text.trim().isNotEmpty;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _image = result.files.first);
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pdf = result.files.first);
    }
  }

  Future<void> _submit() async {
    final resume = context.read<ResumeState>();
    if (resume.resumeText == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final (draft, application) = await context.read<JobsState>().draftCustomJob(
            imageBytes: _image?.bytes?.toList(),
            imageFileName: _image?.name,
            pdfBytes: _pdf?.bytes?.toList(),
            pdfFileName: _pdf?.name,
            prompt: _promptController.text,
            resumeText: resume.rebuiltResume ?? resume.resumeText!,
            targetRole: resume.targetRole,
          );
      if (!mounted) return;
      await showDraftReviewSheet(context, draft: draft, application: application);
      if (mounted) {
        setState(() {
          _image = null;
          _pdf = null;
          _promptController.clear();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resume = context.watch<ResumeState>();

    return Scaffold(
      backgroundColor: AuroraColors.void_,
      appBar: AppBar(
        backgroundColor: AuroraColors.void_,
        elevation: 0,
        title: Text('Add your own job', style: AuroraText.displayM.copyWith(fontSize: 17)),
      ),
      body: resume.resumeText == null ? _needsResume() : _form(resume),
    );
  }

  Widget _needsResume() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuroraSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined, size: 36, color: AuroraColors.mistDim),
            const SizedBox(height: AuroraSpacing.md),
            Text('Scan a resume first', style: AuroraText.displayM, textAlign: TextAlign.center),
            const SizedBox(height: AuroraSpacing.sm),
            Text(
              'Aura tailors your resume against your scanned resume — head to the Resume tab and run a scan, then come back here.',
              style: AuroraText.body.copyWith(color: AuroraColors.mist),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(ResumeState resume) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Found a job somewhere else? Upload a screenshot or PDF of the posting — or just paste it in — and Aura will tailor your resume for it, the same way it does for feed matches.",
              style: AuroraText.body.copyWith(color: AuroraColors.mist, fontSize: 13.5),
            ),
            const SizedBox(height: AuroraSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _AttachmentTile(
                    icon: Icons.image_outlined,
                    label: 'Screenshot',
                    fileName: _image?.name,
                    onTap: _pickImage,
                    onClear: () => setState(() => _image = null),
                  ),
                ),
                const SizedBox(width: AuroraSpacing.md),
                Expanded(
                  child: _AttachmentTile(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    fileName: _pdf?.name,
                    onTap: _pickPdf,
                    onClear: () => setState(() => _pdf = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AuroraSpacing.lg),
            Text('Description or notes (optional)', style: AuroraText.bodySm.copyWith(color: AuroraColors.mist)),
            const SizedBox(height: AuroraSpacing.sm),
            TextField(
              controller: _promptController,
              onChanged: (_) => setState(() {}),
              minLines: 4,
              maxLines: 8,
              style: AuroraText.body,
              decoration: InputDecoration(
                hintText: 'Paste the job description here, or add anything the screenshot/PDF might miss…',
                hintStyle: AuroraText.body.copyWith(color: AuroraColors.mistDim),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                contentPadding: const EdgeInsets.all(16),
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
            ),
            if (_error != null) ...[
              const SizedBox(height: AuroraSpacing.md),
              Text(_error!, style: AuroraText.bodySm.copyWith(color: AuroraColors.danger)),
            ],
            const SizedBox(height: AuroraSpacing.xl),
            AuroraButton(
              label: _submitting ? 'Reading & tailoring…' : 'Generate tailored resume',
              icon: Icons.auto_fix_high_outlined,
              expand: true,
              onPressed: (!_canSubmit || _submitting) ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.icon,
    required this.label,
    required this.fileName,
    required this.onTap,
    required this.onClear,
  });

  final IconData icon;
  final String label;
  final String? fileName;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final picked = fileName != null;
    return GestureDetector(
      onTap: picked ? null : onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        borderColor: picked ? AuroraColors.cyan.withValues(alpha: 0.3) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: picked ? AuroraColors.cyan : AuroraColors.mistDim),
            const SizedBox(height: AuroraSpacing.sm),
            Text(
              fileName ?? label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AuroraText.bodySm.copyWith(color: picked ? AuroraColors.ink : AuroraColors.mist),
            ),
            if (picked) ...[
              const SizedBox(height: AuroraSpacing.xs),
              GestureDetector(
                onTap: onClear,
                child: Text('Remove', style: AuroraText.mono.copyWith(fontSize: 10, color: AuroraColors.danger)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
