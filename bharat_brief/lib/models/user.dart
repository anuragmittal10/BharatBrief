class QuizStats {
  final int streak;
  final int totalScore;
  final int bestStreak;
  final int quizzesPlayed;

  QuizStats({
    this.streak = 0,
    this.totalScore = 0,
    this.bestStreak = 0,
    this.quizzesPlayed = 0,
  });

  factory QuizStats.fromJson(Map<String, dynamic> json) {
    return QuizStats(
      streak: json['streak'] as int? ?? 0,
      totalScore: json['total_score'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
      quizzesPlayed: json['quizzes_played'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streak': streak,
      'total_score': totalScore,
      'best_streak': bestStreak,
      'quizzes_played': quizzesPlayed,
    };
  }

  QuizStats copyWith({
    int? streak,
    int? totalScore,
    int? bestStreak,
    int? quizzesPlayed,
  }) {
    return QuizStats(
      streak: streak ?? this.streak,
      totalScore: totalScore ?? this.totalScore,
      bestStreak: bestStreak ?? this.bestStreak,
      quizzesPlayed: quizzesPlayed ?? this.quizzesPlayed,
    );
  }
}

class UserPreferences {
  final String fontSize;
  final bool darkMode;
  final bool notificationMorning;
  final bool notificationBreaking;
  final bool notificationQuiz;
  final bool dataSaver;
  final String readingMode;

  UserPreferences({
    this.fontSize = 'medium',
    this.darkMode = false,
    this.notificationMorning = true,
    this.notificationBreaking = true,
    this.notificationQuiz = true,
    this.dataSaver = false,
    this.readingMode = 'quick',
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      fontSize: json['font_size'] as String? ?? 'medium',
      darkMode: json['dark_mode'] as bool? ?? false,
      notificationMorning: json['notification_morning'] as bool? ?? true,
      notificationBreaking: json['notification_breaking'] as bool? ?? true,
      notificationQuiz: json['notification_quiz'] as bool? ?? true,
      dataSaver: json['data_saver'] as bool? ?? false,
      readingMode: json['reading_mode'] as String? ?? 'quick',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'font_size': fontSize,
      'dark_mode': darkMode,
      'notification_morning': notificationMorning,
      'notification_breaking': notificationBreaking,
      'notification_quiz': notificationQuiz,
      'data_saver': dataSaver,
      'reading_mode': readingMode,
    };
  }

  UserPreferences copyWith({
    String? fontSize,
    bool? darkMode,
    bool? notificationMorning,
    bool? notificationBreaking,
    bool? notificationQuiz,
    bool? dataSaver,
    String? readingMode,
  }) {
    return UserPreferences(
      fontSize: fontSize ?? this.fontSize,
      darkMode: darkMode ?? this.darkMode,
      notificationMorning: notificationMorning ?? this.notificationMorning,
      notificationBreaking: notificationBreaking ?? this.notificationBreaking,
      notificationQuiz: notificationQuiz ?? this.notificationQuiz,
      dataSaver: dataSaver ?? this.dataSaver,
      readingMode: readingMode ?? this.readingMode,
    );
  }
}

class AppUser {
  final String uid;
  final String language;
  final String state;
  final List<String> categories;
  final List<String> bookmarks;
  final QuizStats quizStats;
  final UserPreferences preferences;

  AppUser({
    required this.uid,
    this.language = 'en',
    this.state = '',
    this.categories = const ['national', 'sports', 'tech'],
    this.bookmarks = const [],
    QuizStats? quizStats,
    UserPreferences? preferences,
  })  : quizStats = quizStats ?? QuizStats(),
        preferences = preferences ?? UserPreferences();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      state: json['state'] as String? ?? '',
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          ['national', 'sports', 'tech'],
      bookmarks: (json['bookmarks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      quizStats: json['quiz_stats'] != null
          ? QuizStats.fromJson(json['quiz_stats'] as Map<String, dynamic>)
          : QuizStats(),
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(
              json['preferences'] as Map<String, dynamic>)
          : UserPreferences(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'language': language,
      'state': state,
      'categories': categories,
      'bookmarks': bookmarks,
      'quiz_stats': quizStats.toJson(),
      'preferences': preferences.toJson(),
    };
  }

  AppUser copyWith({
    String? uid,
    String? language,
    String? state,
    List<String>? categories,
    List<String>? bookmarks,
    QuizStats? quizStats,
    UserPreferences? preferences,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      language: language ?? this.language,
      state: state ?? this.state,
      categories: categories ?? this.categories,
      bookmarks: bookmarks ?? this.bookmarks,
      quizStats: quizStats ?? this.quizStats,
      preferences: preferences ?? this.preferences,
    );
  }
}
