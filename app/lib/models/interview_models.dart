import 'resume_models.dart' show ScoreCategory;

class InterviewResult {
  InterviewResult({
    required this.overallScore,
    required this.categories,
    required this.strengths,
    required this.improvements,
    required this.verdict,
  });

  final int overallScore;
  final List<ScoreCategory> categories;
  final List<String> strengths;
  final List<String> improvements;
  final String verdict;

  factory InterviewResult.fromJson(Map<String, dynamic> json) => InterviewResult(
        overallScore: json['overallScore'] as int? ?? 0,
        categories: (json['categories'] as List? ?? const [])
            .map((e) => ScoreCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
        strengths: List<String>.from(json['strengths'] as List? ?? const []),
        improvements: List<String>.from(json['improvements'] as List? ?? const []),
        verdict: json['verdict'] as String? ?? '',
      );
}
