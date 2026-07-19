import 'resume_models.dart' show ScoreCategory;

/// Grounds an interview session in a real job posting instead of just a
/// target-role string — pass this when launching Prep from a specific job.
class InterviewJobContext {
  const InterviewJobContext({required this.jobTitle, this.companyName, this.jobDescription});

  final String jobTitle;
  final String? companyName;
  final String? jobDescription;

  Map<String, dynamic> toJson() => {
        'jobTitle': jobTitle,
        if (companyName != null) 'companyName': companyName,
        if (jobDescription != null) 'jobDescription': jobDescription,
      };
}

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
