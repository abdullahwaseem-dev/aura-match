import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/resume_state.dart';
import '../../../theme/aurora.dart';
import '../../../widgets/aurora_button.dart';
import '../../../widgets/glass_container.dart';

class UploadView extends StatefulWidget {
  const UploadView({super.key});

  @override
  State<UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<UploadView> {
  final _roleController = TextEditingController();
  PlatformFile? _picked;

  @override
  void dispose() {
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _picked = result.files.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ResumeState>();
    final canSubmit = _picked != null && _roleController.text.trim().isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SMART RESUME BUILDER', style: AuroraText.caption.copyWith(color: AuroraColors.cyanSoft)),
            const SizedBox(height: 10),
            Text('Upload your resume', style: AuroraText.displayM),
            const SizedBox(height: 8),
            Text(
              "Aura scans it the way real ATS parsers do, then rebuilds it with you.",
              style: AuroraText.body.copyWith(color: AuroraColors.mist),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickFile,
              child: GlassContainer(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Icon(
                      _picked == null ? Icons.upload_file_outlined : Icons.description_outlined,
                      size: 34,
                      color: _picked == null ? AuroraColors.mistDim : AuroraColors.cyan,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _picked?.name ?? 'Tap to choose a PDF, DOCX, or TXT',
                      textAlign: TextAlign.center,
                      style: AuroraText.body.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Target role', style: AuroraText.bodySm.copyWith(color: AuroraColors.mist)),
            const SizedBox(height: 8),
            TextField(
              controller: _roleController,
              onChanged: (_) => setState(() {}),
              style: AuroraText.body,
              decoration: InputDecoration(
                hintText: 'e.g. Senior Product Designer',
                hintStyle: AuroraText.body.copyWith(color: AuroraColors.mistDim),
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
            ),
            const SizedBox(height: 28),
            AuroraButton(
              label: state.loading ? 'Scanning…' : 'Scan my resume',
              expand: true,
              onPressed: (!canSubmit || state.loading)
                  ? null
                  : () => context.read<ResumeState>().uploadResume(
                        bytes: _picked!.bytes!.toList(),
                        name: _picked!.name,
                        role: _roleController.text.trim(),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
