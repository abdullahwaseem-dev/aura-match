class ParserScore {
  ParserScore({required this.parser, required this.score});
  final String parser;
  final int score;

  factory ParserScore.fromJson(Map<String, dynamic> json) =>
      ParserScore(parser: json['parser'] as String, score: json['score'] as int);
}

class AtsScanResult {
  AtsScanResult({
    required this.atsScore,
    required this.parserBreakdown,
    required this.matchedKeywords,
    required this.missingKeywords,
    required this.questions,
  });

  final int atsScore;
  final List<ParserScore> parserBreakdown;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final List<String> questions;

  factory AtsScanResult.fromJson(Map<String, dynamic> json) => AtsScanResult(
        atsScore: json['atsScore'] as int,
        parserBreakdown: (json['parserBreakdown'] as List)
            .map((e) => ParserScore.fromJson(e as Map<String, dynamic>))
            .toList(),
        matchedKeywords: List<String>.from(json['matchedKeywords'] as List),
        missingKeywords: List<String>.from(json['missingKeywords'] as List),
        questions: List<String>.from(json['questions'] as List),
      );
}

class QaAnswer {
  QaAnswer({required this.question, required this.answer});
  final String question;
  final String answer;

  Map<String, dynamic> toJson() => {'question': question, 'answer': answer};
}

class ChatMessage {
  ChatMessage({required this.text, required this.fromAura});
  final String text;
  final bool fromAura;
}

class ScoreCategory {
  ScoreCategory({required this.name, required this.score});
  final String name;
  final int score;

  factory ScoreCategory.fromJson(Map<String, dynamic> json) =>
      ScoreCategory(name: json['name'] as String, score: json['score'] as int);
}

class HiringManagerScorecard {
  HiringManagerScorecard({
    required this.overallScore,
    required this.categories,
    required this.benchmarkPercentile,
    required this.feedback,
  });

  final int overallScore;
  final List<ScoreCategory> categories;
  final int benchmarkPercentile;
  final List<String> feedback;

  factory HiringManagerScorecard.fromJson(Map<String, dynamic> json) => HiringManagerScorecard(
        overallScore: json['overallScore'] as int,
        categories:
            (json['categories'] as List).map((e) => ScoreCategory.fromJson(e as Map<String, dynamic>)).toList(),
        benchmarkPercentile: json['benchmarkPercentile'] as int,
        feedback: List<String>.from(json['feedback'] as List),
      );
}

class HiringManagerPersona {
  const HiringManagerPersona({required this.label, required this.rubric, required this.region});
  final String label;
  final String rubric;
  final String region;

  static const all = [
    HiringManagerPersona(label: 'SaaS, Series B', rubric: 'SaaS, Series B, US', region: 'US'),
    HiringManagerPersona(label: 'Enterprise Tech', rubric: 'Enterprise software, UK/EU', region: 'UK/EU'),
    HiringManagerPersona(label: 'Manufacturing', rubric: 'Manufacturing, DACH', region: 'DACH'),
    HiringManagerPersona(label: 'Consumer Startup', rubric: 'Consumer startup, APAC', region: 'APAC'),
  ];
}
