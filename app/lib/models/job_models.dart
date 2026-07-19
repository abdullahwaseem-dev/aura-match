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

class ResumeExperience {
  ResumeExperience({required this.role, required this.company, required this.dates, required this.bullets});

  final String role;
  final String company;
  final String dates;
  final List<String> bullets;

  factory ResumeExperience.fromJson(Map<String, dynamic> json) => ResumeExperience(
        role: json['role'] as String? ?? '',
        company: json['company'] as String? ?? '',
        dates: json['dates'] as String? ?? '',
        bullets: List<String>.from(json['bullets'] as List? ?? const []),
      );
}

class ResumeEducation {
  ResumeEducation({required this.credential, required this.institution, required this.dates});

  final String credential;
  final String institution;
  final String dates;

  factory ResumeEducation.fromJson(Map<String, dynamic> json) => ResumeEducation(
        credential: json['credential'] as String? ?? '',
        institution: json['institution'] as String? ?? '',
        dates: json['dates'] as String? ?? '',
      );
}

/// A full resume rewritten for one specific job — rendered on screen and
/// exported to PDF.
class TailoredResume {
  TailoredResume({
    required this.fullName,
    required this.headline,
    required this.contact,
    required this.summary,
    required this.skills,
    required this.experience,
    required this.education,
  });

  final String fullName;
  final String headline;
  final String contact;
  final String summary;
  final List<String> skills;
  final List<ResumeExperience> experience;
  final List<ResumeEducation> education;

  factory TailoredResume.fromJson(Map<String, dynamic> json) => TailoredResume(
        fullName: json['fullName'] as String? ?? '',
        headline: json['headline'] as String? ?? '',
        contact: json['contact'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        skills: List<String>.from(json['skills'] as List? ?? const []),
        experience: (json['experience'] as List? ?? const [])
            .map((e) => ResumeExperience.fromJson(e as Map<String, dynamic>))
            .toList(),
        education: (json['education'] as List? ?? const [])
            .map((e) => ResumeEducation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ApplicationDraft {
  ApplicationDraft({required this.resume, required this.coverNote});

  final TailoredResume resume;
  final String coverNote;

  factory ApplicationDraft.fromJson(Map<String, dynamic> json) => ApplicationDraft(
        resume: TailoredResume.fromJson(json['resume'] as Map<String, dynamic>),
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
