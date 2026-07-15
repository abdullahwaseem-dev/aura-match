# AURA MATCH — Flutter Technical Architecture

Clean Architecture + MVVM, one codebase for iOS, Android, macOS, and Web.

This is the target architecture for the production build. The current code in `lib/` (from the first working prototype) is a flat `ChangeNotifier` + direct `ApiClient` calls — it proved the product loop end-to-end but doesn't scale past one feature. The **Migration Path** section at the end maps every existing file onto its new home.

---

## 1. Principles

**The Dependency Rule: dependencies only point inward.**

```
Presentation  →  Domain  ←  Data
   (View,           ↑        (Models, DataSources,
   ViewModel)        |         RepositoryImpl)
                (zero outward deps)
```

- **Domain** is pure Dart. No `flutter/material.dart`, no `dio`, no `http`. It defines *what the app does*, not how.
- **Presentation** (View + ViewModel) depends on Domain only — it calls UseCases and reads Entities. It never imports a `*Model` (DTO) or a `RemoteDataSource`.
- **Data** implements Domain's contracts. It's the only layer that knows a JSON key exists, a header is required, or a URL looks like `/api/resume/scan`.

Three layers, one rule, and every part of it becomes independently testable — that's the entire payoff.

| Layer | Contains | Depends on | Flutter SDK? |
|---|---|---|---|
| **Domain** | Entities, Repository interfaces, UseCases | nothing | No |
| **Data** | Models (DTOs), DataSources, Repository implementations | Domain | No (uses `dio`, not `flutter`) |
| **Presentation** | ViewModels, Screens, Widgets | Domain | Yes |

---

## 2. Folder Structure

Feature-first, with Clean Architecture layers nested inside each feature. `core/` holds only things every feature needs — it never imports from `features/`.

```
lib/
├── main.dart                          # runApp() only
├── bootstrap.dart                     # DI setup, error zone, env load
│
├── core/
│   ├── config/
│   │   └── app_config.dart            # API base URL, env flags, build flavor
│   ├── di/
│   │   └── injector.dart              # get_it registrations for every feature
│   ├── error/
│   │   ├── failures.dart              # Failure sealed class (domain-facing)
│   │   └── exceptions.dart            # *Exception thrown by the data layer
│   ├── network/
│   │   ├── api_client.dart            # Dio wrapper: base client, interceptors
│   │   └── network_info.dart          # connectivity check
│   ├── result/
│   │   └── result.dart                # Result<T> sealed class (Success/Error)
│   ├── router/
│   │   └── app_router.dart            # go_router route table
│   ├── theme/                         # Aurora design tokens (already built)
│   ├── usecase/
│   │   └── usecase.dart               # abstract UseCase<Type, Params>
│   └── widgets/                       # dumb, reusable UI — GlassContainer, AuroraButton…
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/user_model.dart
│   │   │   ├── datasources/auth_remote_data_source.dart
│   │   │   └── repositories/auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/user.dart
│   │   │   ├── repositories/auth_repository.dart      # abstract
│   │   │   └── usecases/sign_in.dart, sign_up.dart, get_current_user.dart
│   │   └── presentation/
│   │       ├── viewmodels/auth_viewmodel.dart
│   │       ├── screens/sign_in_screen.dart
│   │       └── widgets/
│   │
│   ├── resume_builder/
│   │   ├── data/
│   │   │   ├── models/resume_model.dart, ats_scan_result_model.dart
│   │   │   ├── datasources/resume_remote_data_source.dart
│   │   │   └── repositories/resume_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/resume.dart, ats_scan_result.dart, qa_pair.dart
│   │   │   ├── repositories/resume_repository.dart
│   │   │   └── usecases/
│   │   │       ├── parse_resume.dart
│   │   │       ├── scan_resume.dart
│   │   │       └── rebuild_resume.dart
│   │   └── presentation/
│   │       ├── viewmodels/resume_builder_viewmodel.dart
│   │       ├── screens/upload_screen.dart, scan_result_screen.dart, qa_chat_screen.dart, draft_preview_screen.dart
│   │       └── widgets/
│   │
│   ├── hiring_manager/
│   │   ├── data/   …
│   │   ├── domain/
│   │   │   ├── entities/scorecard.dart, persona.dart
│   │   │   └── usecases/score_resume.dart
│   │   └── presentation/
│   │       ├── viewmodels/hiring_manager_viewmodel.dart
│   │       └── screens/persona_picker_screen.dart, scorecard_screen.dart
│   │
│   ├── job_search/
│   │   ├── data/
│   │   │   ├── models/job_post_model.dart, application_model.dart
│   │   │   ├── datasources/
│   │   │   │   ├── job_search_remote_data_source.dart      # REST: preferences, apply
│   │   │   │   └── job_match_socket_data_source.dart       # WebSocket: live match feed
│   │   │   └── repositories/job_search_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/job_post.dart, application.dart
│   │   │   ├── repositories/job_search_repository.dart
│   │   │   └── usecases/
│   │   │       ├── watch_job_matches.dart
│   │   │       ├── auto_apply_to_job.dart                  # consent-gate rule lives here
│   │   │       └── track_applications.dart
│   │   └── presentation/
│   │       ├── viewmodels/job_search_viewmodel.dart
│   │       └── screens/match_feed_screen.dart, application_tracker_screen.dart
│   │
│   ├── interview_prep/
│   │   ├── data/
│   │   │   ├── models/interview_question_model.dart
│   │   │   ├── datasources/interview_remote_data_source.dart   # streamed AI responses
│   │   │   └── repositories/interview_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/interview_question.dart, interview_session.dart, answer_feedback.dart
│   │   │   ├── repositories/interview_repository.dart
│   │   │   └── usecases/start_session.dart, submit_answer.dart, get_performance_report.dart
│   │   └── presentation/
│   │       ├── viewmodels/interview_session_viewmodel.dart
│   │       └── screens/live_session_screen.dart, performance_report_screen.dart
│   │
│   └── home/
│       └── presentation/
│           ├── viewmodels/home_viewmodel.dart
│           └── screens/aura_home_screen.dart
│
└── shared/
    └── extensions/                    # tiny cross-feature helpers only — keep this folder small
```

**Rule of thumb for where new code goes:** if it describes a business rule ("auto-apply requires ≥85% fit and the user's consent switch"), it's a **UseCase**. If it shapes JSON, it's a **Model**. If it holds `notifyListeners()` and screen state, it's a **ViewModel**. If it's just pixels, it's a **Widget**.

---

## 3. Core Data Models

Domain entities are immutable, `Equatable`, and carry zero JSON knowledge — they're what the rest of the app is allowed to think in.

```dart
// features/auth/domain/entities/user.dart
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.plan,
    required this.autoApplyEnabled,
  });

  final String id;
  final String email;
  final String name;
  final SubscriptionPlan plan;
  final bool autoApplyEnabled; // the Privacy & Data master switch — see job_search below

  @override
  List<Object?> get props => [id, email, name, plan, autoApplyEnabled];
}

enum SubscriptionPlan { free, pro, unlimited }
```

```dart
// features/resume_builder/domain/entities/resume.dart
class Resume extends Equatable {
  const Resume({
    required this.id,
    required this.fileName,
    required this.rawText,
    required this.targetRole,
    this.atsScore,
    this.matchedKeywords = const [],
    this.missingKeywords = const [],
    this.rebuiltText,
  });

  final String id;
  final String fileName;
  final String rawText;
  final String targetRole;
  final int? atsScore;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final String? rebuiltText;

  bool get hasBeenScanned => atsScore != null;
  bool get hasBeenRebuilt => rebuiltText != null;

  @override
  List<Object?> get props =>
      [id, fileName, rawText, targetRole, atsScore, matchedKeywords, missingKeywords, rebuiltText];
}
```

```dart
// features/job_search/domain/entities/job_post.dart
class JobPost extends Equatable {
  const JobPost({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.remote,
    required this.fitScore,
    required this.sourceUrl,
    this.salaryMin,
    this.salaryMax,
    this.applicationStatus = ApplicationStatus.notApplied,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final bool remote;
  final int fitScore; // 0–100, Aura's match confidence
  final Uri sourceUrl;
  final int? salaryMin;
  final int? salaryMax;
  final ApplicationStatus applicationStatus;

  /// The UI-level mirror of this rule lives in AutoApplyToJob (domain) — see §4.
  bool get qualifiesForAutoApply => fitScore >= 85;

  @override
  List<Object?> get props =>
      [id, title, company, location, remote, fitScore, sourceUrl, salaryMin, salaryMax, applicationStatus];
}

enum ApplicationStatus { notApplied, applied, viewed, interview, offer, rejected }
```

```dart
// features/interview_prep/domain/entities/interview_question.dart
class InterviewQuestion extends Equatable {
  const InterviewQuestion({
    required this.id,
    required this.prompt,
    required this.category,
    this.userAnswer,
    this.feedback,
  });

  final String id;
  final String prompt;
  final QuestionCategory category;
  final String? userAnswer;
  final AnswerFeedback? feedback;

  @override
  List<Object?> get props => [id, prompt, category, userAnswer, feedback];
}

enum QuestionCategory { behavioral, technical, situational, cultureFit }

class AnswerFeedback extends Equatable {
  const AnswerFeedback({required this.structureScore, required this.paceScore, required this.note});

  final int structureScore; // STAR-structure adherence, 0–100
  final int paceScore;      // 0–100
  final String note;

  @override
  List<Object?> get props => [structureScore, paceScore, note];
}
```

### Data Models (DTOs) — the JSON boundary

Every entity gets a matching `*Model` in the **data** layer that knows how to parse the backend's JSON and convert itself into the entity above. Nothing outside `data/` ever sees this class.

```dart
// features/resume_builder/data/models/ats_scan_result_model.dart
class AtsScanResultModel {
  const AtsScanResultModel({
    required this.atsScore,
    required this.matchedKeywords,
    required this.missingKeywords,
    required this.questions,
  });

  final int atsScore;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final List<String> questions;

  factory AtsScanResultModel.fromJson(Map<String, dynamic> json) => AtsScanResultModel(
        atsScore: json['atsScore'] as int,
        matchedKeywords: List<String>.from(json['matchedKeywords'] as List),
        missingKeywords: List<String>.from(json['missingKeywords'] as List),
        questions: List<String>.from(json['questions'] as List),
      );

  /// The only bridge between "what the backend sent" and "what the app thinks in."
  AtsScanResult toEntity() => AtsScanResult(
        score: atsScore,
        matchedKeywords: matchedKeywords,
        missingKeywords: missingKeywords,
        clarifyingQuestions: questions,
      );
}
```

If Aura's backend ever renames `atsScore` to `score`, or a job board integration hands back a wildly different shape, exactly one file changes. The ViewModel, the Screen, and every test written against `AtsScanResult` don't notice.

---

## 4. ViewModels — MVVM in Practice

A ViewModel:
1. depends only on **UseCases** (never on a Repository or DataSource directly — that's what makes it unit-testable with zero mocking of HTTP),
2. exposes state as a **sealed class** so the View's `switch` is exhaustive — no `if (loading) ... else if (error) ...` chains that miss a case,
3. holds *no* business rules. "Is this fit score good enough to auto-apply?" is a UseCase's question, not a ViewModel's.

```dart
// core/result/result.dart
sealed class Result<T> {
  const Result();
}
final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}
final class Error<T> extends Result<T> {
  const Error(this.failure);
  final Failure failure;
}
```

```dart
// core/error/failures.dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Check your connection and try again.']);
}
final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}
final class AiRefusalFailure extends Failure {
  const AiRefusalFailure(super.message);
}
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
```

### 4.1 — Uploading a file (Smart Resume Builder)

```dart
// features/resume_builder/presentation/viewmodels/resume_builder_viewmodel.dart
sealed class ResumeBuilderState {
  const ResumeBuilderState();
}
final class ResumeIdle extends ResumeBuilderState {
  const ResumeIdle();
}
final class ResumeWorking extends ResumeBuilderState {
  const ResumeWorking(this.message);
  final String message;
}
final class ResumeScanned extends ResumeBuilderState {
  const ResumeScanned(this.resume, this.scan);
  final Resume resume;
  final AtsScanResult scan;
}
final class ResumeFailed extends ResumeBuilderState {
  const ResumeFailed(this.failure);
  final Failure failure;
}

class ResumeBuilderViewModel extends ChangeNotifier {
  ResumeBuilderViewModel({
    required ParseResume parseResume,
    required ScanResume scanResume,
  })  : _parseResume = parseResume,
        _scanResume = scanResume;

  final ParseResume _parseResume;
  final ScanResume _scanResume;

  ResumeBuilderState state = const ResumeIdle();

  Future<void> uploadAndScan({
    required List<int> bytes,
    required String fileName,
    required String targetRole,
  }) async {
    _emit(const ResumeWorking('Reading your resume…'));

    final parsed = await _parseResume(ParseResumeParams(bytes: bytes, fileName: fileName));
    final Resume resume;
    switch (parsed) {
      case Error(:final failure):
        return _emit(ResumeFailed(failure));
      case Success(:final data):
        resume = data.copyWith(targetRole: targetRole);
    }

    _emit(const ResumeWorking('Scanning against real ATS parsers…'));
    final scanned = await _scanResume(ScanResumeParams(resumeText: resume.rawText, targetRole: targetRole));
    switch (scanned) {
      case Error(:final failure):
        _emit(ResumeFailed(failure));
      case Success(:final data):
        _emit(ResumeScanned(resume, data));
    }
  }

  void _emit(ResumeBuilderState next) {
    state = next;
    notifyListeners();
  }
}
```

The View becomes a dumb `switch`:

```dart
Widget build(BuildContext context) {
  final state = context.watch<ResumeBuilderViewModel>().state;
  return switch (state) {
    ResumeIdle() => const UploadPrompt(),
    ResumeWorking(:final message) => LoadingView(message: message),
    ResumeScanned(:final scan) => ScanResultView(scan: scan),
    ResumeFailed(:final failure) => ErrorView(message: failure.message),
  };
}
```

### 4.2 — Chatting with the AI Hiring Manager / Interview Simulator (streamed)

Both are the same shape: the user says something, Aura's reply arrives token-by-token so the UI can render it live instead of freezing for 3 seconds. The pattern is identical to the file-upload ViewModel, except the DataSource returns a `Stream<String>` instead of a `Future`.

```dart
// features/interview_prep/domain/repositories/interview_repository.dart
abstract interface class InterviewRepository {
  Stream<String> streamReaction({required String sessionId, required String question, required String answer});
}
```

```dart
// features/interview_prep/presentation/viewmodels/interview_session_viewmodel.dart
class InterviewSessionViewModel extends ChangeNotifier {
  InterviewSessionViewModel({required this.sessionId, required InterviewRepository repository})
      : _repository = repository;

  final String sessionId;
  final InterviewRepository _repository;

  final List<TranscriptEntry> transcript = [];
  bool auraIsTyping = false;

  Future<void> submitAnswer({required String question, required String answer}) async {
    transcript.add(TranscriptEntry.user(answer));
    transcript.add(TranscriptEntry.aura('')); // placeholder bubble Aura fills in live
    auraIsTyping = true;
    notifyListeners();

    final buffer = StringBuffer();
    try {
      await for (final token in _repository.streamReaction(sessionId: sessionId, question: question, answer: answer)) {
        buffer.write(token);
        transcript[transcript.length - 1] = TranscriptEntry.aura(buffer.toString());
        notifyListeners();
      }
    } finally {
      auraIsTyping = false;
      notifyListeners();
    }
  }
}
```

Nothing here knows about Server-Sent Events, chunked HTTP, or the Anthropic SDK — that's entirely inside the DataSource (§5). The ViewModel just consumes a `Stream<String>`, which means it's just as easy to unit-test with a fake `Stream.fromIterable(['Hel', 'lo'])` as with the real network.

### 4.3 — Running the automatic job search

This is the one place the plan differs from the other two: the *business rule* — "only auto-apply at ≥85% fit, and only if the user has switched auto-apply on" — must not live in the ViewModel, because the ViewModel is UI-adjacent and every screen that could ever trigger an apply (Match Feed, Job Detail, a future "bulk apply" button) would have to remember to reimplement it. It goes in a UseCase instead, so it's enforced exactly once no matter who calls it.

```dart
// features/job_search/domain/usecases/auto_apply_to_job.dart
class AutoApplyToJob implements UseCase<Application, AutoApplyParams> {
  const AutoApplyToJob(this._repository);
  final JobSearchRepository _repository;

  static const _autoApplyThreshold = 85;

  @override
  Future<Result<Application>> call(AutoApplyParams params) async {
    if (!params.userHasEnabledAutoApply) {
      return const Error(ValidationFailure(
        'Turn on auto-apply in Privacy & Data to let Aura submit on your behalf.',
      ));
    }
    if (params.job.fitScore < _autoApplyThreshold) {
      return const Error(ValidationFailure(
        'This match is below the auto-apply threshold — review it yourself first.',
      ));
    }
    return _repository.applyToJob(jobId: params.job.id, resumeId: params.resumeId);
  }
}
```

The ViewModel watches a live match feed (a `Stream<List<JobPost>>` backed by a WebSocket — see §5) and defers every apply decision to the UseCase above:

```dart
// features/job_search/presentation/viewmodels/job_search_viewmodel.dart
class JobSearchViewModel extends ChangeNotifier {
  JobSearchViewModel({required WatchJobMatches watchMatches, required AutoApplyToJob autoApply})
      : _watchMatches = watchMatches,
        _autoApply = autoApply;

  final WatchJobMatches _watchMatches;
  final AutoApplyToJob _autoApply;
  StreamSubscription<List<JobPost>>? _subscription;

  List<JobPost> matches = [];
  String? lastError;

  void startWatching(String resumeId) {
    _subscription?.cancel();
    _subscription = _watchMatches(resumeId).listen((jobs) {
      matches = jobs;
      notifyListeners();
    });
  }

  Future<void> apply(JobPost job, {required String resumeId, required bool autoApplyEnabled}) async {
    final result = await _autoApply(AutoApplyParams(
      job: job,
      resumeId: resumeId,
      userHasEnabledAutoApply: autoApplyEnabled,
    ));
    switch (result) {
      case Success():
        lastError = null;
      case Error(:final failure):
        lastError = failure.message;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

---

## 5. Third-Party APIs — Keeping the Integration Clean

**Rule: the Flutter app never talks to Claude, OpenAI, or a job-scraping service directly.** Two reasons, not just one:

- **Security.** An API key shipped inside a compiled app — iOS, Android, or Web — is an API key anyone can extract. It has to live server-side.
- **Architecture.** If the client called Anthropic directly, every one of the four platforms would duplicate the prompt logic, and swapping models later means four PRs instead of one.

So the real integration point is the backend already running in `server/` (Node/Express + the Anthropic SDK). Flutter's **DataSource** classes are the *only* code aware that backend exists — they're the wall between "the app's idea of a Resume" and "whatever shape a specific vendor's API happens to return."

```dart
// features/resume_builder/data/datasources/resume_remote_data_source.dart
abstract interface class ResumeRemoteDataSource {
  Future<AtsScanResultModel> scanResume({required String resumeText, required String targetRole});
}

class ResumeRemoteDataSourceImpl implements ResumeRemoteDataSource {
  const ResumeRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<AtsScanResultModel> scanResume({required String resumeText, required String targetRole}) async {
    final response = await _client.post('/api/resume/scan', data: {
      'resumeText': resumeText,
      'targetRole': targetRole,
    });
    return AtsScanResultModel.fromJson(response.data as Map<String, dynamic>);
  }
}
```

The Repository is the seam between Data and Domain — it converts transport failures into domain `Failure`s and DTOs into Entities, so nothing above this line ever catches a `DioException`:

```dart
// features/resume_builder/data/repositories/resume_repository_impl.dart
class ResumeRepositoryImpl implements ResumeRepository {
  const ResumeRepositoryImpl(this._remote);
  final ResumeRemoteDataSource _remote;

  @override
  Future<Result<AtsScanResult>> scanResume({required String resumeText, required String targetRole}) async {
    try {
      final dto = await _remote.scanResume(resumeText: resumeText, targetRole: targetRole);
      return Success(dto.toEntity());
    } on AiRefusalException catch (e) {
      return Error(AiRefusalFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } on DioException {
      return const Error(NetworkFailure());
    }
  }
}
```

### Web scraping (Automatic Job Search)

The scraper is **not** a Flutter concern at all, and it's not even in the request path of the API the app calls. It's a separate backend worker — a scheduled job or queue consumer living in `server/` — that crawls job boards, normalizes results, and writes `JobPost` rows to a database. The Express API the app talks to just reads from that store and pushes new matches down the WebSocket. This keeps three things clean at once: the app never waits on a live crawl, ToS/robots.txt handling stays entirely server-side where it can be governed, and the consent-gate rule from §4.3 has one enforcement point instead of racing a scraper's own logic.

```dart
// features/job_search/data/datasources/job_match_socket_data_source.dart
abstract interface class JobMatchSocketDataSource {
  Stream<List<JobPostModel>> watchMatches(String resumeId);
}

class JobMatchSocketDataSourceImpl implements JobMatchSocketDataSource {
  const JobMatchSocketDataSourceImpl(this._channelFactory);
  final WebSocketChannel Function(String path) _channelFactory;

  @override
  Stream<List<JobPostModel>> watchMatches(String resumeId) {
    final channel = _channelFactory('/ws/job-matches/$resumeId');
    return channel.stream.map((raw) {
      final list = jsonDecode(raw as String) as List;
      return list.map((e) => JobPostModel.fromJson(e as Map<String, dynamic>)).toList();
    });
  }
}
```

### The Dio client every DataSource shares

```dart
// core/network/api_client.dart
class ApiClient {
  ApiClient(this._dio) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = AuthSession.instance.token;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) {
        // Map a 503 "AI not configured" or an Aura refusal into a typed exception
        // here, once, so every repository's catch block above stays simple.
        handler.next(error);
      },
    ));
  }

  final Dio _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _dio.get<T>(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, {Object? data}) => _dio.post<T>(path, data: data);
}
```

**Payoff:** to switch AI providers, add a fallback model, or replace the scraping vendor, the diff is contained to `server/` plus the handful of DataSource files that shape its JSON. Every Screen, ViewModel, UseCase, and Entity in the app is unaffected — and every one of them can be unit-tested by swapping in a fake implementation of the same interface, no live network required.

---

## 6. Dependency Injection

`get_it` as a service locator, wired once at startup.

```dart
// core/di/injector.dart
final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Core
  getIt.registerLazySingleton<Dio>(() => Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)));
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt()));

  // Resume Builder feature
  getIt.registerLazySingleton<ResumeRemoteDataSource>(() => ResumeRemoteDataSourceImpl(getIt()));
  getIt.registerLazySingleton<ResumeRepository>(() => ResumeRepositoryImpl(getIt()));
  getIt.registerFactory(() => ParseResume(getIt()));
  getIt.registerFactory(() => ScanResume(getIt()));
  getIt.registerFactory(() => RebuildResume(getIt()));
  getIt.registerFactory(() => ResumeBuilderViewModel(parseResume: getIt(), scanResume: getIt()));

  // Job Search feature
  getIt.registerLazySingleton<JobMatchSocketDataSource>(() => JobMatchSocketDataSourceImpl(getIt()));
  getIt.registerLazySingleton<JobSearchRepository>(() => JobSearchRepositoryImpl(getIt(), getIt()));
  getIt.registerFactory(() => WatchJobMatches(getIt()));
  getIt.registerFactory(() => AutoApplyToJob(getIt()));

  // …one block per feature, same shape every time
}
```

```dart
// main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const AuraMatchApp());
}
```

ViewModels are provided **per-screen**, not globally — a `ResumeBuilderViewModel` should live exactly as long as the Resume Builder flow is on screen, not for the app's entire lifetime:

```dart
ChangeNotifierProvider(
  create: (_) => getIt<ResumeBuilderViewModel>(),
  child: const ResumeFlowScreen(),
);
```

---

## 7. Testing Strategy

The whole point of the three layers is that each one is testable without the other two:

| Layer | Test type | What you mock |
|---|---|---|
| Domain (UseCases) | Pure unit test | The Repository interface (one fake class, no HTTP) |
| Data (Repositories, DataSources) | Unit test | `Dio` via `DioAdapter`, or a fake `ApiClient` |
| Presentation (ViewModels) | Unit test, no widget pump | The UseCases (fakes returning canned `Result`s) — proves state transitions without booting Flutter |
| Presentation (Screens) | Widget/golden test | The ViewModel itself, via a fake with preset `state` |

A ViewModel test never touches the network, and a UseCase test never touches Flutter. That split is what makes the AI-pipeline logic (§4.3's threshold rule, in particular) safe to change with confidence.

---

## 8. Migration Path from the Current Prototype

The existing `lib/` isn't wasted — it's the reference implementation for what each piece should *do*, before being split into layers. Feature by feature, not a rewrite:

| Today | Becomes |
|---|---|
| `lib/services/api_client.dart` | `core/network/api_client.dart` (the Dio wrapper) + one `*RemoteDataSource` per feature |
| `lib/models/resume_models.dart` | Split into `features/resume_builder/domain/entities/*.dart` (clean) and `features/resume_builder/data/models/*.dart` (JSON-aware) |
| `lib/state/resume_state.dart` | Splits into `ResumeBuilderViewModel` + `HiringManagerViewModel`, each backed by 2–3 UseCases and a `ResumeRepository` |
| `lib/screens/resume/*` | Move as-is into `features/resume_builder/presentation/screens/`; swap `context.read<ResumeState>()` for the new ViewModel's equivalent method |
| `lib/screens/home`, `jobs`, `interview`, `profile` | Become `features/home`, `features/job_search`, `features/interview_prep`, `features/profile` — currently placeholders, so they start clean in the new structure directly |
| `lib/theme`, `lib/widgets` (Aurora design system) | Move into `core/theme/` and `core/widgets/` unchanged — this layer was already framework-agnostic-within-Flutter and needs no rework |

Recommended order: **Resume Builder first** (it's the most complete flow today, so it validates the pattern), then Hiring Manager, then scaffold Job Search and Interview Prep directly in the new structure since their current code is just placeholders.

I can execute this migration — starting with Resume Builder — whenever you want it done; this document is the spec for it.
