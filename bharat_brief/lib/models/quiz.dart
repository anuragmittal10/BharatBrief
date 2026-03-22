class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? articleId;
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.articleId,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      correctIndex: json['correct_index'] as int? ?? 0,
      articleId: json['article_id'] as String?,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correct_index': correctIndex,
      'article_id': articleId,
      'explanation': explanation,
    };
  }
}

class Quiz {
  final String id;
  final DateTime date;
  final List<QuizQuestion> questions;
  final String? title;

  Quiz({
    required this.id,
    required this.date,
    required this.questions,
    this.title,
  });

  int get totalQuestions => questions.length;

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      questions: (json['questions'] as List<dynamic>?)
              ?.map(
                  (e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      title: json['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'title': title,
    };
  }
}

class QuizResult {
  final int score;
  final int total;
  final int streak;
  final int bestStreak;
  final List<bool> answers;

  QuizResult({
    required this.score,
    required this.total,
    required this.streak,
    required this.bestStreak,
    required this.answers,
  });

  double get percentage => total > 0 ? (score / total) * 100 : 0;

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      score: json['score'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'total': total,
      'streak': streak,
      'best_streak': bestStreak,
      'answers': answers,
    };
  }
}
