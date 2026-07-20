class UserProfile {
  UserProfile({required this.autoDraftEnabled});

  final bool autoDraftEnabled;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      UserProfile(autoDraftEnabled: json['auto_draft_enabled'] as bool? ?? false);
}

class SavedResume {
  SavedResume({
    required this.id,
    required this.fileName,
    required this.targetRole,
    required this.atsScore,
    required this.updatedAt,
  });

  final String id;
  final String fileName;
  final String targetRole;
  final int? atsScore;
  final DateTime updatedAt;

  factory SavedResume.fromJson(Map<String, dynamic> json) => SavedResume(
        id: json['id'] as String,
        fileName: json['file_name'] as String,
        targetRole: json['target_role'] as String,
        atsScore: json['ats_score'] as int?,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class SavedResumeDetail extends SavedResume {
  SavedResumeDetail({
    required super.id,
    required super.fileName,
    required super.targetRole,
    required super.atsScore,
    required super.updatedAt,
    required this.resumeText,
  });

  final String resumeText;

  factory SavedResumeDetail.fromJson(Map<String, dynamic> json) => SavedResumeDetail(
        id: json['id'] as String,
        fileName: json['file_name'] as String,
        targetRole: json['target_role'] as String,
        atsScore: json['ats_score'] as int?,
        updatedAt: DateTime.parse(json['updated_at'] as String),
        resumeText: json['resume_text'] as String,
      );
}
