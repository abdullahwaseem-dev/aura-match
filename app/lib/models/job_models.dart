enum ApplicationStatus { saved, drafting, ready, applied, interviewing, offer, rejected }

ApplicationStatus _statusFromJson(String value) =>
    ApplicationStatus.values.firstWhere((s) => s.name == value, orElse: () => ApplicationStatus.saved);

class JobListing {
  JobListing({
    required this.id,
    required this.title,
    required this.companyName,
    required this.location,
    required this.remote,
    required this.description,
    required this.applyUrl,
    required this.tags,
  });

  final String id;
  final String title;
  final String companyName;
  final String? location;
  final bool remote;
  final String description;
  final String applyUrl;
  final List<String> tags;

  factory JobListing.fromJson(Map<String, dynamic> json) => JobListing(
        id: json['id'] as String,
        title: json['title'] as String,
        companyName: json['company_name'] as String,
        location: json['location'] as String?,
        remote: json['remote'] as bool? ?? false,
        description: json['description'] as String? ?? '',
        applyUrl: json['apply_url'] as String,
        tags: List<String>.from(json['tags'] as List? ?? const []),
      );
}

class JobMatch {
  JobMatch({required this.job, required this.matchScore, required this.reasons});

  final JobListing job;
  final int matchScore;
  final List<String> reasons;

  factory JobMatch.fromJson(Map<String, dynamic> json) => JobMatch(
        job: JobListing.fromJson(json['job'] as Map<String, dynamic>),
        matchScore: json['matchScore'] as int,
        reasons: List<String>.from(json['reasons'] as List? ?? const []),
      );
}

class ApplicationDraft {
  ApplicationDraft({required this.tailoredSummary, required this.tailoredHighlights, required this.coverNote});

  final String tailoredSummary;
  final List<String> tailoredHighlights;
  final String coverNote;

  factory ApplicationDraft.fromJson(Map<String, dynamic> json) => ApplicationDraft(
        tailoredSummary: json['tailoredSummary'] as String? ?? '',
        tailoredHighlights: List<String>.from(json['tailoredHighlights'] as List? ?? const []),
        coverNote: json['coverNote'] as String? ?? '',
      );
}

class TrackedApplication {
  TrackedApplication({
    required this.id,
    required this.job,
    required this.status,
    required this.tailoredResume,
    required this.coverNote,
    required this.updatedAt,
  });

  final String id;
  final JobListing job;
  final ApplicationStatus status;
  final String? tailoredResume;
  final String? coverNote;
  final DateTime updatedAt;

  factory TrackedApplication.fromJson(Map<String, dynamic> json) => TrackedApplication(
        id: json['id'] as String,
        job: JobListing.fromJson(json['job'] as Map<String, dynamic>),
        status: _statusFromJson(json['status'] as String),
        tailoredResume: json['tailored_resume'] as String?,
        coverNote: json['cover_note'] as String?,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

extension ApplicationStatusLabel on ApplicationStatus {
  String get label {
    switch (this) {
      case ApplicationStatus.saved:
        return 'Saved';
      case ApplicationStatus.drafting:
        return 'Drafting';
      case ApplicationStatus.ready:
        return 'Ready to apply';
      case ApplicationStatus.applied:
        return 'Applied';
      case ApplicationStatus.interviewing:
        return 'Interviewing';
      case ApplicationStatus.offer:
        return 'Offer';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }
}
