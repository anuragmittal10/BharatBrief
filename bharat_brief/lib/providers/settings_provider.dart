import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;

  String _fontSize = 'medium';
  ThemeMode _themeMode = ThemeMode.system;
  bool _notifMorning = true;
  bool _notifBreaking = true;
  bool _notifQuiz = true;
  bool _dataSaver = false;
  String _readingMode = 'quick';

  SettingsProvider({required StorageService storage}) : _storage = storage;

  String get fontSize => _fontSize;
  ThemeMode get themeMode => _themeMode;
  bool get notifMorning => _notifMorning;
  bool get notifBreaking => _notifBreaking;
  bool get notifQuiz => _notifQuiz;
  bool get dataSaver => _dataSaver;
  String get readingMode => _readingMode;

  double get fontScale {
    switch (_fontSize) {
      case 'small':
        return 0.85;
      case 'large':
        return 1.2;
      default:
        return 1.0;
    }
  }

  Future<void> loadFromStorage() async {
    _fontSize = _storage.getFontSize();
    final isDark = _storage.getDarkMode();
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _notifMorning = _storage.getNotifMorning();
    _notifBreaking = _storage.getNotifBreaking();
    _notifQuiz = _storage.getNotifQuiz();
    _dataSaver = _storage.getDataSaver();
    _readingMode = _storage.getReadingMode();
    notifyListeners();
  }

  Future<void> setFontSize(String size) async {
    _fontSize = size;
    await _storage.setFontSize(size);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.setDarkMode(mode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      await _storage.setDarkMode(false);
    } else {
      _themeMode = ThemeMode.dark;
      await _storage.setDarkMode(true);
    }
    notifyListeners();
  }

  Future<void> setNotifMorning(bool val) async {
    _notifMorning = val;
    await _storage.setNotifMorning(val);
    notifyListeners();
  }

  Future<void> setNotifBreaking(bool val) async {
    _notifBreaking = val;
    await _storage.setNotifBreaking(val);
    notifyListeners();
  }

  Future<void> setNotifQuiz(bool val) async {
    _notifQuiz = val;
    await _storage.setNotifQuiz(val);
    notifyListeners();
  }

  Future<void> setDataSaver(bool val) async {
    _dataSaver = val;
    await _storage.setDataSaver(val);
    notifyListeners();
  }

  Future<void> setReadingMode(String mode) async {
    _readingMode = mode;
    await _storage.setReadingMode(mode);
    notifyListeners();
  }

  void cycleReadingMode() {
    switch (_readingMode) {
      case 'quick':
        setReadingMode('deep');
        break;
      case 'deep':
        setReadingMode('feelgood');
        break;
      default:
        setReadingMode('quick');
    }
  }

  IconData get readingModeIcon {
    switch (_readingMode) {
      case 'quick':
        return Icons.flash_on;
      case 'deep':
        return Icons.menu_book;
      case 'feelgood':
        return Icons.favorite;
      default:
        return Icons.flash_on;
    }
  }

  String get readingModeLabel {
    switch (_readingMode) {
      case 'quick':
        return 'Quick Read';
      case 'deep':
        return 'Deep Dive';
      case 'feelgood':
        return 'Feel Good';
      default:
        return 'Quick Read';
    }
  }
}
