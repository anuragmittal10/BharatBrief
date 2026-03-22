class Summary {
  final String headline;
  final String summary;

  Summary({
    required this.headline,
    required this.summary,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      headline: json['headline'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headline': headline,
      'summary': summary,
    };
  }
}

class Article {
  final String id;
  final String title;
  final String source;
  final String category;
  final String? state;
  final String? imageUrl;
  final String originalLink;
  final DateTime publishedAt;
  final Map<String, Summary> summaries;
  final Map<String, String> ttsUrls;
  final bool isTrending;
  final String moodTag;

  Article({
    required this.id,
    required this.title,
    required this.source,
    required this.category,
    this.state,
    this.imageUrl,
    required this.originalLink,
    required this.publishedAt,
    required this.summaries,
    this.ttsUrls = const {},
    this.isTrending = false,
    this.moodTag = 'neutral',
  });

  String getHeadline(String langCode) {
    final s = summaries[langCode] ?? summaries['en'];
    return s?.headline ?? title;
  }

  String getSummary(String langCode) {
    final s = summaries[langCode] ?? summaries['en'];
    return s?.summary ?? '';
  }

  String? getTtsUrl(String langCode) {
    return ttsUrls[langCode];
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    final summariesMap = <String, Summary>{};
    if (json['summaries'] != null) {
      (json['summaries'] as Map<String, dynamic>).forEach((key, value) {
        summariesMap[key] = Summary.fromJson(value as Map<String, dynamic>);
      });
    }

    final ttsMap = <String, String>{};
    if (json['tts_urls'] != null) {
      (json['tts_urls'] as Map<String, dynamic>).forEach((key, value) {
        ttsMap[key] = value as String;
      });
    }

    return Article(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      source: json['source'] as String? ?? '',
      category: json['category'] as String? ?? 'national',
      state: json['state'] as String?,
      imageUrl: json['image_url'] as String?,
      originalLink: json['original_link'] as String? ?? '',
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      summaries: summariesMap,
      ttsUrls: ttsMap,
      isTrending: json['is_trending'] as bool? ?? false,
      moodTag: json['mood_tag'] as String? ?? 'neutral',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'source': source,
      'category': category,
      'state': state,
      'image_url': imageUrl,
      'original_link': originalLink,
      'published_at': publishedAt.toIso8601String(),
      'summaries': summaries.map((k, v) => MapEntry(k, v.toJson())),
      'tts_urls': ttsUrls,
      'is_trending': isTrending,
      'mood_tag': moodTag,
    };
  }

  Article copyWith({
    String? id,
    String? title,
    String? source,
    String? category,
    String? state,
    String? imageUrl,
    String? originalLink,
    DateTime? publishedAt,
    Map<String, Summary>? summaries,
    Map<String, String>? ttsUrls,
    bool? isTrending,
    String? moodTag,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      source: source ?? this.source,
      category: category ?? this.category,
      state: state ?? this.state,
      imageUrl: imageUrl ?? this.imageUrl,
      originalLink: originalLink ?? this.originalLink,
      publishedAt: publishedAt ?? this.publishedAt,
      summaries: summaries ?? this.summaries,
      ttsUrls: ttsUrls ?? this.ttsUrls,
      isTrending: isTrending ?? this.isTrending,
      moodTag: moodTag ?? this.moodTag,
    );
  }
}
