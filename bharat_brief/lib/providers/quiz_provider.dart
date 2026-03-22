import 'package:flutter/foundation.dart';
import '../models/quiz.dart';
import '../services/api_service.dart';

class QuizProvider extends ChangeNotifier {
  final ApiService _api;

  Quiz? _todayQuiz;
  int _currentQuestionIndex = 0;
  List<int?> _selectedAnswers = [];
  int _score = 0;
  bool _isComplete = false;
  bool _isLoading = false;
  String? _error;
  bool _hasAnsweredCurrent = false;
  QuizResult? _result;
  bool _hintUsed = false;

  QuizProvider({required ApiService api}) : _api = api;

  Quiz? get todayQuiz => _todayQuiz;
  int get currentQuestionIndex => _currentQuestionIndex;
  List<int?> get selectedAnswers => _selectedAnswers;
  int get score => _score;
  bool get isComplete => _isComplete;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasAnsweredCurrent => _hasAnsweredCurrent;
  QuizResult? get result => _result;
  bool get hintUsed => _hintUsed;

  QuizQuestion? get currentQuestion {
    if (_todayQuiz == null ||
        _currentQuestionIndex >= _todayQuiz!.questions.length) {
      return null;
    }
    return _todayQuiz!.questions[_currentQuestionIndex];
  }

  int get totalQuestions => _todayQuiz?.questions.length ?? 0;
  bool get hasQuiz => _todayQuiz != null && _todayQuiz!.questions.isNotEmpty;

  double get progress {
    if (totalQuestions == 0) return 0;
    return (_currentQuestionIndex + (_hasAnsweredCurrent ? 1 : 0)) /
        totalQuestions;
  }

  Future<void> fetchQuiz() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todayQuiz = await _api.getTodayQuiz();
      _selectedAnswers =
          List<int?>.filled(_todayQuiz!.questions.length, null);
      _currentQuestionIndex = 0;
      _score = 0;
      _isComplete = false;
      _hasAnsweredCurrent = false;
      _result = null;
      _hintUsed = false;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        _error = 'quiz_not_available';
      } else {
        _error = e.message;
      }
      _todayQuiz = null;
    } on NetworkException {
      _error = 'No internet connection';
      _todayQuiz = null;
    } catch (e) {
      _error = 'Failed to load quiz';
      _todayQuiz = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void answerQuestion(int selectedIndex) {
    if (_hasAnsweredCurrent || _todayQuiz == null) return;

    final question = _todayQuiz!.questions[_currentQuestionIndex];
    _selectedAnswers[_currentQuestionIndex] = selectedIndex;
    _hasAnsweredCurrent = true;

    if (selectedIndex == question.correctIndex) {
      _score++;
    }

    notifyListeners();
  }

  void nextQuestion() {
    if (!_hasAnsweredCurrent) return;

    if (_currentQuestionIndex < totalQuestions - 1) {
      _currentQuestionIndex++;
      _hasAnsweredCurrent = false;
      _hintUsed = false;
      notifyListeners();
    } else {
      _isComplete = true;
      notifyListeners();
    }
  }

  Future<void> submitQuiz(String uid) async {
    if (_todayQuiz == null) return;

    try {
      final answers = _selectedAnswers
          .map((a) => a ?? -1)
          .toList();
      _result = await _api.submitQuiz(uid, _todayQuiz!.id, answers);
    } catch (_) {
      // Create local result if API fails
      final correctAnswers = <bool>[];
      for (int i = 0; i < totalQuestions; i++) {
        correctAnswers.add(
          _selectedAnswers[i] == _todayQuiz!.questions[i].correctIndex,
        );
      }
      _result = QuizResult(
        score: _score,
        total: totalQuestions,
        streak: 1,
        bestStreak: 1,
        answers: correctAnswers,
      );
    }
    notifyListeners();
  }

  void useHint() {
    _hintUsed = true;
    notifyListeners();
  }

  /// Returns an option index to eliminate (a wrong answer that's not the correct one)
  int? getHintElimination() {
    if (currentQuestion == null || _hasAnsweredCurrent) return null;
    final correct = currentQuestion!.correctIndex;
    for (int i = 0; i < currentQuestion!.options.length; i++) {
      if (i != correct) return i;
    }
    return null;
  }

  void resetQuiz() {
    _todayQuiz = null;
    _currentQuestionIndex = 0;
    _selectedAnswers = [];
    _score = 0;
    _isComplete = false;
    _hasAnsweredCurrent = false;
    _result = null;
    _hintUsed = false;
    _error = null;
    notifyListeners();
  }

  String getShareText() {
    return 'I scored $_score/$totalQuestions on today\'s BharatBrief News Quiz! '
        'Test your knowledge: https://bharatbrief.com/quiz';
  }
}
