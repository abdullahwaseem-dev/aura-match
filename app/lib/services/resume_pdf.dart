import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/job_models.dart';

/// Renders a [TailoredResume] to a clean, ATS-friendly PDF and hands it to the
/// platform's share/print/download sheet. Works on web (browser download),
/// mobile (share sheet), and desktop (print dialog).
class ResumePdf {
  static Future<void> shareTailoredResume({
    required TailoredResume resume,
    required String jobTitle,
    required String company,
  }) async {
    final doc = await _build(resume);
    final safeCompany = company.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final safeName = (resume.fullName.isEmpty ? 'Resume' : resume.fullName)
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    await Printing.sharePdf(bytes: await doc.save(), filename: '${safeName}_$safeCompany.pdf');
  }

  /// The PDF standard Helvetica font only reliably renders plain WinAnsi
  /// punctuation — smart quotes, em/en dashes, bullets, and ellipses from
  /// LLM-generated text render as missing-glyph boxes. Normalize everything
  /// to plain ASCII equivalents before it reaches a pw.Text.
  static String _safe(String s) {
    return s
        .replaceAll(RegExp('[‘’‚‛]'), "'")
        .replaceAll(RegExp('[“”„‟]'), '"')
        .replaceAll(RegExp('[–—]'), '-')
        .replaceAll('•', '-')
        .replaceAll('…', '...') // ellipsis
        .replaceAll(String.fromCharCode(0xA0), ' '); // non-breaking space
  }

  static Future<pw.Document> _build(TailoredResume resume) async {
    final doc = pw.Document();
    // Uses the PDF standard Helvetica family — no font assets to bundle, and
    // it renders identically everywhere while staying ATS-parseable.
    final theme = pw.ThemeData.base();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(40, 44, 40, 44),
        build: (context) => [
          _header(resume),
          if (resume.summary.isNotEmpty)
            _section('SUMMARY', pw.Text(_safe(resume.summary), style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 2))),
          if (resume.skills.isNotEmpty) _section('SKILLS', _skills(resume.skills)),
          if (resume.experience.isNotEmpty) _section('EXPERIENCE', _experience(resume.experience)),
          if (resume.projects.isNotEmpty) _section('PROJECTS', _projects(resume.projects)),
          if (resume.education.isNotEmpty) _section('EDUCATION', _education(resume.education)),
          if (resume.languages.isNotEmpty)
            _section(
              'LANGUAGES',
              pw.Text(resume.languages.map(_safe).join('   *   '), style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 2)),
            ),
        ],
      ),
    );
    return doc;
  }

  static pw.Widget _header(TailoredResume resume) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (resume.fullName.isNotEmpty)
          pw.Text(_safe(resume.fullName), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        if (resume.headline.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(_safe(resume.headline), style: const pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey700)),
          ),
        if (resume.contact.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(_safe(resume.contact), style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
          ),
        pw.SizedBox(height: 6),
        pw.Divider(thickness: 0.8, color: PdfColors.grey400),
      ],
    );
  }

  static pw.Widget _section(String title, pw.Widget body) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2, color: PdfColors.blueGrey800)),
          pw.SizedBox(height: 6),
          body,
        ],
      ),
    );
  }

  static pw.Widget _skills(List<ResumeSkillCategory> categories) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: categories.map((c) {
        final items = c.items.map(_safe).join(', ');
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                if (c.category.isNotEmpty)
                  pw.TextSpan(
                    text: '${_safe(c.category)}: ',
                    style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                  ),
                pw.TextSpan(text: items, style: const pw.TextStyle(fontSize: 10.5)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _projects(List<ResumeProject> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items.map((p) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: pw.Text(_safe(p.name), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
                  if (p.context.isNotEmpty)
                    pw.Text(_safe(p.context), style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey600)),
                ],
              ),
              if (p.description.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(_safe(p.description), style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 1.4)),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _experience(List<ResumeExperience> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items.map((e) {
        final header = [e.role, e.company].where((s) => s.isNotEmpty).map(_safe).join('  -  ');
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: pw.Text(header, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
                  if (e.dates.isNotEmpty)
                    pw.Text(_safe(e.dates), style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey600)),
                ],
              ),
              pw.SizedBox(height: 3),
              ...e.bullets.map(
                (b) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2, left: 8),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('-  ', style: const pw.TextStyle(fontSize: 10.5)),
                      pw.Expanded(child: pw.Text(_safe(b), style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 1.5))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _education(List<ResumeEducation> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items.map((ed) {
        final line = [ed.credential, ed.institution].where((s) => s.isNotEmpty).map(_safe).join('  -  ');
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(line, style: const pw.TextStyle(fontSize: 10.5))),
              if (ed.dates.isNotEmpty) pw.Text(_safe(ed.dates), style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
