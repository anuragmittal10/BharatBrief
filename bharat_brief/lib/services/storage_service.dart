import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';

class StorageService {
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyLanguage = 'language';
  static const String _keyState = 'state';
  static const String _keyCategories = 'categories';
  static const String _keyFontSize = 'font_size';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyUserId = 'user_id';
  static const String _keyReadingMode = 'reading_mode';
  static const String _keyNotifMorning = 'notif_morning';
  static const String _keyNotifBreaking = 'notif_breaking';
  static const String _keyNotifQuiz = 'notif_quiz';
  static const String _keyDataSaver = 'data_saver';
  static const String _keyBookmarks = 'bookmarks';
  static const String _cacheFileName = 'article_cache.json';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // First launch
  bool get isFirstLaunch => _prefs.getBool(_keyFirstLaunch) ?? true;

  Future<void> setFirstLaunchDone() async {
    await _prefs.setBool(_keyFirstLaunch, false);
  }

  // Language
  String getLanguage() => _prefs.getString(_keyLanguage) ?? 'en';

  Future<void> setLanguage(String code) async {
    await _prefs.setString(_keyLanguage, code);
  }

  // State
  String getState() => _prefs.getString(_keyState) ?? '';

  Future<void> setState(String code) async {
    await _prefs.setString(_keyState, code);
  }

  // Categories
  List<String> getCategories() {
    return _prefs.getStringList(_keyCategories) ??
        ['national', 'sports', 'tech'];
  }

  Future<void> setCategories(List<String> categories) async {
    await _prefs.setStringList(_keyCategories, categories);
  }

  // Font size
  String getFontSize() => _prefs.getString(_keyFontSize) ?? 'medium';

  Future<void> setFontSize(String size) async {
    await _prefs.setString(_keyFontSize, size);
  }

  // Dark mode
  bool getDarkMode() => _prefs.getBool(_keyDarkMode) ?? false;

  Future<void> setDarkMode(bool enabled) async {
    await _prefs.setBool(_keyDarkMode, enabled);
  }

  // User ID
  String? getUserId() => _prefs.getString(_keyUserId);

  Future<void> setUserId(String uid) async {
    await _prefs.setString(_keyUserId, uid);
  }

  // Reading mode
  String getReadingMode() => _prefs.getString(_keyReadingMode) ?? 'quick';

  Future<void> setReadingMode(String mode) async {
    await _prefs.setString(_keyReadingMode, mode);
  }

  // Notifications
  bool getNotifMorning() => _prefs.getBool(_keyNotifMorning) ?? true;
  bool getNotifBreaking() => _prefs.getBool(_keyNotifBreaking) ?? true;
  bool getNotifQuiz() => _prefs.getBool(_keyNotifQuiz) ?? true;

  Future<void> setNotifMorning(bool val) async {
    await _prefs.setBool(_keyNotifMorning, val);
  }

  Future<void> setNotifBreaking(bool val) async {
    await _prefs.setBool(_keyNotifBreaking, val);
  }

  Future<void> setNotifQuiz(bool val) async {
    await _prefs.setBool(_keyNotifQuiz, val);
  }

  // Data saver
  bool getDataSaver() => _prefs.getBool(_keyDataSaver) ?? false;

  Future<void> setDataSaver(bool val) async {
    await _prefs.setBool(_keyDataSaver, val);
  }

  // Bookmarks (local)
  List<String> getBookmarkIds() {
    return _prefs.getStringList(_keyBookmarks) ?? [];
  }

  Future<void> setBookmarkIds(List<String> ids) async {
    await _prefs.setStringList(_keyBookmarks, ids);
  }

  // Offline article cache
  Future<String> get _cacheDir async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<void> cacheArticles(List<Article> articles) async {
    try {
      final dir = await _cacheDir;
      final file = File('$dir/$_cacheFileName');
      final jsonList = articles.map((a) => a.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (_) {
      // Silently fail cache writes
    }
  }

  Future<List<Article>> getCachedArticles() async {
    try {
      final dir = await _cacheDir;
      final file = File('$dir/$_cacheFileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonList = jsonDecode(content) as List<dynamic>;
        return jsonList
            .map((e) => Article.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Return empty on cache read failure
    }
    return [];
  }

  Future<void> clearCache() async {
    try {
      final dir = await _cacheDir;
      final file = File('$dir/$_cacheFileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Silently fail
    }
  }
}
