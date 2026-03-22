import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  final StorageService _storage;
  final ApiService _api;

  AppUser _user = AppUser(uid: '');
  bool _isLoading = false;
  String? _error;

  UserProvider({
    required StorageService storage,
    required ApiService api,
  })  : _storage = storage,
        _api = api;

  AppUser get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get language => _user.language;
  String get state => _user.state;
  List<String> get categories => _user.categories;
  List<String> get bookmarks => _user.bookmarks;
  QuizStats get quizStats => _user.quizStats;
  UserPreferences get preferences => _user.preferences;
  bool get isLoggedIn => _user.uid.isNotEmpty;

  Future<void> loadFromStorage() async {
    final uid = _storage.getUserId() ?? '';
    final lang = _storage.getLanguage();
    final st = _storage.getState();
    final cats = _storage.getCategories();
    final bookmarkIds = _storage.getBookmarkIds();
    final fontSize = _storage.getFontSize();
    final darkMode = _storage.getDarkMode();
    final readingMode = _storage.getReadingMode();
    final notifMorning = _storage.getNotifMorning();
    final notifBreaking = _storage.getNotifBreaking();
    final notifQuiz = _storage.getNotifQuiz();
    final dataSaver = _storage.getDataSaver();

    _user = AppUser(
      uid: uid,
      language: lang,
      state: st,
      categories: cats,
      bookmarks: bookmarkIds,
      preferences: UserPreferences(
        fontSize: fontSize,
        darkMode: darkMode,
        readingMode: readingMode,
        notificationMorning: notifMorning,
        notificationBreaking: notifBreaking,
        notificationQuiz: notifQuiz,
        dataSaver: dataSaver,
      ),
    );
    notifyListeners();
  }

  Future<void> registerUser({
    required String language,
    required String state,
    required List<String> categories,
    String? fcmToken,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final registeredUser = await _api.registerUser(
        language: language,
        state: state,
        categories: categories,
        fcmToken: fcmToken,
      );

      _user = registeredUser;
      await _storage.setUserId(registeredUser.uid);
      await _storage.setLanguage(language);
      await _storage.setState(state);
      await _storage.setCategories(categories);
      await _storage.setFirstLaunchDone();
    } catch (e) {
      // If API fails, create local user
      _user = AppUser(
        uid: 'local_${DateTime.now().millisecondsSinceEpoch}',
        language: language,
        state: state,
        categories: categories,
      );
      await _storage.setUserId(_user.uid);
      await _storage.setLanguage(language);
      await _storage.setState(state);
      await _storage.setCategories(categories);
      await _storage.setFirstLaunchDone();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    _user = _user.copyWith(language: code);
    await _storage.setLanguage(code);
    _syncPreferences();
    notifyListeners();
  }

  Future<void> setUserState(String code) async {
    _user = _user.copyWith(state: code);
    await _storage.setState(code);
    _syncPreferences();
    notifyListeners();
  }

  Future<void> toggleCategory(String category) async {
    final cats = List<String>.from(_user.categories);
    if (cats.contains(category)) {
      if (cats.length > 1) cats.remove(category);
    } else {
      cats.add(category);
    }
    _user = _user.copyWith(categories: cats);
    await _storage.setCategories(cats);
    _syncPreferences();
    notifyListeners();
  }

  Future<void> setCategories(List<String> categories) async {
    _user = _user.copyWith(categories: categories);
    await _storage.setCategories(categories);
    _syncPreferences();
    notifyListeners();
  }

  Future<void> addBookmark(String articleId) async {
    if (_user.bookmarks.contains(articleId)) return;
    final newBookmarks = List<String>.from(_user.bookmarks)..add(articleId);
    _user = _user.copyWith(bookmarks: newBookmarks);
    await _storage.setBookmarkIds(newBookmarks);
    notifyListeners();

    try {
      if (_user.uid.isNotEmpty && !_user.uid.startsWith('local_')) {
        await _api.addBookmark(_user.uid, articleId);
      }
    } catch (_) {
      // Bookmark saved locally even if API fails
    }
  }

  Future<void> removeBookmark(String articleId) async {
    final newBookmarks = List<String>.from(_user.bookmarks)..remove(articleId);
    _user = _user.copyWith(bookmarks: newBookmarks);
    await _storage.setBookmarkIds(newBookmarks);
    notifyListeners();

    try {
      if (_user.uid.isNotEmpty && !_user.uid.startsWith('local_')) {
        await _api.removeBookmark(_user.uid, articleId);
      }
    } catch (_) {
      // Bookmark removed locally even if API fails
    }
  }

  bool isBookmarked(String articleId) {
    return _user.bookmarks.contains(articleId);
  }

  Future<void> setFontSize(String size) async {
    _user = _user.copyWith(
      preferences: _user.preferences.copyWith(fontSize: size),
    );
    await _storage.setFontSize(size);
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _user = _user.copyWith(
      preferences: _user.preferences.copyWith(darkMode: enabled),
    );
    await _storage.setDarkMode(enabled);
    notifyListeners();
  }

  Future<void> setReadingMode(String mode) async {
    _user = _user.copyWith(
      preferences: _user.preferences.copyWith(readingMode: mode),
    );
    await _storage.setReadingMode(mode);
    notifyListeners();
  }

  Future<void> setNotificationMorning(bool val) async {
    _user = _user.copyWith(
      preferences: _user.preferences.copyWith(notificationMorning: val),
    );
    await _storage.setNotifMorning(val);
    _syncPreferences();
    notifyListeners();
  }

  Future<void> setNotificationBreaking(bool val) async {
    _user = _user.copyWith(
      preferences: _user.preferences.copyWith(notificationBreaking: val),
    );
    await _storage.setNotifBreaking(val);
    _syncPreferences();
    notifyListeners();
  }

  Future<void> setNotificationQuiz(bool val) async {
    _user = _user.copyWith(
      preferences: _user.preferences.copyWith(notificationQuiz: val),
    );
    await _storage.setNotifQuiz(val);
    _syncPreferences();
    notifyListeners();
  }

  Future<void> setDataSaver(bool val) async {
    _user = _user.copyWith(
      preferences: _user.preferences.copyWith(dataSaver: val),
    );
    await _storage.setDataSaver(val);
    notifyListeners();
  }

  Future<void> updateQuizScore(int score, int streak) async {
    final newStats = _user.quizStats.copyWith(
      totalScore: _user.quizStats.totalScore + score,
      streak: streak,
      bestStreak: streak > _user.quizStats.bestStreak
          ? streak
          : _user.quizStats.bestStreak,
      quizzesPlayed: _user.quizStats.quizzesPlayed + 1,
    );
    _user = _user.copyWith(quizStats: newStats);
    notifyListeners();
  }

  void _syncPreferences() {
    if (_user.uid.isNotEmpty && !_user.uid.startsWith('local_')) {
      _api.updatePreferences(_user.uid, _user.toJson()).catchError((_) {});
    }
  }
}
