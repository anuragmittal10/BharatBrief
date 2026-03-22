import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/article.dart';
import '../models/quiz.dart';
import '../models/user.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? AppConstants.apiBaseUrl,
        _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>> _get(
      String path, Map<String, String>? queryParams) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
      print('[ApiService] GET $uri');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(milliseconds: AppConstants.apiTimeout));

      print('[ApiService] Response ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}');
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      print('[ApiService] ClientException: $e');
      throw NetworkException('Connection failed');
    } catch (e) {
      print('[ApiService] Unexpected error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } on http.ClientException {
      throw NetworkException('Connection failed');
    }
  }

  Future<Map<String, dynamic>> _put(
      String path, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _client
          .put(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } on http.ClientException {
      throw NetworkException('Connection failed');
    }
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(const Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } on http.ClientException {
      throw NetworkException('Connection failed');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      throw ApiException('Resource not found', statusCode: 404);
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized', statusCode: 401);
    } else if (response.statusCode >= 500) {
      throw ApiException('Server error', statusCode: response.statusCode);
    } else {
      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : {};
      throw ApiException(
        body['message'] as String? ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
  }

  // Articles
  Future<List<Article>> getArticles({
    required String lang,
    String? category,
    String? state,
    int page = 1,
    int limit = 20,
  }) async {
    final params = {
      'lang': lang,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category != null && category != 'all') params['category'] = category;
    if (state != null && state.isNotEmpty) params['state'] = state;

    final data = await _get('/articles', params);
    final articles = (data['articles'] as List<dynamic>?)
            ?.map((e) => Article.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return articles;
  }

  Future<List<Article>> getTrending({required String lang}) async {
    final data = await _get('/trending', {'lang': lang});
    return (data['articles'] as List<dynamic>?)
            ?.map((e) => Article.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }

  Future<String> getTtsUrl(String articleId, String lang) async {
    final data = await _get('/tts/$articleId/$lang', null);
    return data['url'] as String? ?? '';
  }

  // Quiz
  Future<Quiz> getTodayQuiz() async {
    final data = await _get('/quiz/today', null);
    return Quiz.fromJson(data['quiz'] as Map<String, dynamic>? ?? data);
  }

  Future<QuizResult> submitQuiz(
      String uid, String quizId, List<int> answers) async {
    final data = await _post('/quiz/submit', {
      'uid': uid,
      'quiz_id': quizId,
      'answers': answers,
    });
    return QuizResult.fromJson(data);
  }

  // User
  Future<AppUser> registerUser({
    required String language,
    required String state,
    required List<String> categories,
    String? fcmToken,
  }) async {
    final data = await _post('/user/register', {
      'language': language,
      'state': state,
      'categories': categories,
      'fcm_token': fcmToken,
    });
    return AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }

  Future<void> updatePreferences(
      String uid, Map<String, dynamic> prefs) async {
    await _put('/user/$uid/preferences', prefs);
  }

  // Bookmarks
  Future<List<Article>> getBookmarks(String uid) async {
    final data = await _get('/user/$uid/bookmarks', null);
    return (data['bookmarks'] as List<dynamic>?)
            ?.map((e) => Article.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }

  Future<void> addBookmark(String uid, String articleId) async {
    await _post('/user/$uid/bookmarks/$articleId', {});
  }

  Future<void> removeBookmark(String uid, String articleId) async {
    await _delete('/user/$uid/bookmarks/$articleId');
  }

  // FCM
  Future<void> registerFcmToken(String uid, String token) async {
    await _post('/user/fcm-token', {'uid': uid, 'token': token});
  }

  // Report
  Future<void> reportTranslation(
      String articleId, String lang, String reason) async {
    await _post('/feedback', {
      'article_id': articleId,
      'lang': lang,
      'reason': reason,
      'type': 'bad_translation',
    });
  }

  void dispose() {
    _client.close();
  }
}
