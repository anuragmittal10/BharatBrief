import 'package:flutter/foundation.dart';
import '../models/article.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/constants.dart';

class ArticleProvider extends ChangeNotifier {
  final ApiService _api;
  final StorageService _storage;

  List<Article> _articles = [];
  List<Article> _trending = [];
  List<Article> _bookmarkedArticles = [];
  String _currentCategory = 'all';
  String _currentLanguage = 'en';
  String _currentState = '';
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  bool _isOffline = false;

  ArticleProvider({
    required ApiService api,
    required StorageService storage,
  })  : _api = api,
        _storage = storage;

  List<Article> get articles => _articles;
  List<Article> get trending => _trending;
  List<Article> get bookmarkedArticles => _bookmarkedArticles;
  String get currentCategory => _currentCategory;
  String get currentLanguage => _currentLanguage;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get isOffline => _isOffline;

  Future<void> fetchArticles({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('[ArticleProvider] fetchArticles lang=$_currentLanguage cat=$_currentCategory state=$_currentState page=$_currentPage');
      final newArticles = await _api.getArticles(
        lang: _currentLanguage,
        category: _currentCategory,
        state: _currentState.isNotEmpty ? _currentState : null,
        page: _currentPage,
        limit: AppConstants.articlesPerPage,
      );

      print('[ArticleProvider] Got ${newArticles.length} articles');
      if (refresh) {
        _articles = newArticles;
      } else {
        _articles.addAll(newArticles);
      }

      _hasMore = newArticles.length >= AppConstants.articlesPerPage;
      _currentPage++;
      _isOffline = false;

      // Cache articles for offline use
      await _storage.cacheArticles(_articles);
    } on NetworkException catch (e) {
      print('[ArticleProvider] NetworkException: $e');
      _error = 'No internet connection';
      _isOffline = true;
      if (_articles.isEmpty) {
        // Load from cache
        _articles = await _storage.getCachedArticles();
      }
    } on ApiException catch (e) {
      _error = e.message;
      if (_articles.isEmpty) {
        _articles = await _storage.getCachedArticles();
        _isOffline = _articles.isNotEmpty;
      }
    } catch (e) {
      _error = 'Something went wrong';
      if (_articles.isEmpty) {
        _articles = await _storage.getCachedArticles();
        _isOffline = _articles.isNotEmpty;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTrending() async {
    try {
      _trending = await _api.getTrending(lang: _currentLanguage);
      notifyListeners();
    } catch (_) {
      // Keep existing trending on failure
    }
  }

  Future<void> fetchBookmarkedArticles(String uid) async {
    try {
      _bookmarkedArticles = await _api.getBookmarks(uid);
      notifyListeners();
    } catch (_) {
      // Keep existing bookmarks on failure
    }
  }

  void changeCategory(String category) {
    if (_currentCategory == category) return;
    _currentCategory = category;
    _articles = [];
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
    fetchArticles(refresh: true);
  }

  void changeLanguage(String lang) {
    if (_currentLanguage == lang) return;
    _currentLanguage = lang;
    _articles = [];
    _trending = [];
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
    fetchArticles(refresh: true);
    fetchTrending();
  }

  void changeState(String state) {
    if (_currentState == state) return;
    _currentState = state;
    if (_currentCategory == 'my_state') {
      _articles = [];
      _currentPage = 1;
      _hasMore = true;
      notifyListeners();
      fetchArticles(refresh: true);
    }
  }

  List<Article> searchArticles(String query) {
    if (query.isEmpty) return _articles;
    final lowerQuery = query.toLowerCase();
    return _articles.where((article) {
      final headline =
          article.getHeadline(_currentLanguage).toLowerCase();
      final summary =
          article.getSummary(_currentLanguage).toLowerCase();
      final source = article.source.toLowerCase();
      return headline.contains(lowerQuery) ||
          summary.contains(lowerQuery) ||
          source.contains(lowerQuery);
    }).toList();
  }

  Article? getArticleById(String id) {
    try {
      return _articles.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
