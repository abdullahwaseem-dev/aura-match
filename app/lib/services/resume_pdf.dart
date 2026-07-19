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
    final doc = await _build(resume, jobTitle, company);
    final safeCompany = company.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final safeName = (resume.fullName.isEmpty ? 'Resume' : resume.fullName)
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    await Printing.sharePdf(bytes: await doc.save(), filename: '${safeName}_$safeCompany.pdf');
  }

  static Future<pw.Document> _build(TailoredResume resume, String jobTitle, String company) async {
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
          if (resume.summary.isNotEmpty) _section('SUMMARY', pw.Text(resume.summary, style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 2))),
          if (resume.skills.isNotEmpty)
            _section('SKILLS', pw.Text(resume.skills.join('  ·  '), style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 2))),
          if (resume.experience.isNotEmpty) _section('EXPERIENCE', _experience(resume.experience)),
          if (resume.education.isNotEmpty) _section('EDUCATION', _education(resume.education)),
          pw.SizedBox(height: 18),
          pw.Text(
            'Tailored for $jobTitle at $company',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic),
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
          pw.Text(resume.fullName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        if (resume.headline.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(resume.headline, style: const pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey700)),
          ),
        if (resume.contact.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(resume.contact, style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
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

  static pw.Widget _experience(List<ResumeExperience> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items.map((e) {
        final header = [e.role, e.company].where((s) => s.isNotEmpty).join(' — ');
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
                    pw.Text(e.dates, style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey600)),
                ],
              ),
              pw.SizedBox(height: 3),
              ...e.bullets.map(
                (b) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2, left: 8),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('•  ', style: const pw.TextStyle(fontSize: 10.5)),
                      pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 1.5))),
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
        final line = [ed.credential, ed.institution].where((s) => s.isNotEmpty).join(' — ');
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(line, style: const pw.TextStyle(fontSize: 10.5))),
              if (ed.dates.isNotEmpty) pw.Text(ed.dates, style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
