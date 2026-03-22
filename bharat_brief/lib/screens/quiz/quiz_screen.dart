import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/ad_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  final AdService _adService = AdService();
  late AnimationController _progressAnimController;

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().fetchQuiz();
    });
    try {
      _adService.initialize();
    } catch (_) {}
  }

  @override
  void dispose() {
    _progressAnimController.dispose();
    _adService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daily News Quiz',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.saffron,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(quizProvider),
    );
  }

  Widget _buildBody(QuizProvider quizProvider) {
    if (quizProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.saffron),
      );
    }

    if (quizProvider.error == 'quiz_not_available') {
      return _buildNotAvailable();
    }

    if (quizProvider.error != null) {
      return _buildError(quizProvider);
    }

    if (!quizProvider.hasQuiz) {
      return _buildNotAvailable();
    }

    if (quizProvider.isComplete) {
      return _buildResults(quizProvider);
    }

    return _buildQuizQuestion(quizProvider);
  }

  Widget _buildNotAvailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.saffron.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.quiz,
                size: 64,
                color: AppTheme.saffron,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quiz Available at 8 PM',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Come back at 8 PM for today\'s news quiz!\nTest your knowledge of the day\'s headlines.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.mediumGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Show streak info
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final stats = userProvider.quizStats;
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.local_fire_department,
                        label: 'Streak',
                        value: '${stats.streak}',
                        color: Colors.orange,
                      ),
                      _StatItem(
                        icon: Icons.star,
                        label: 'Total',
                        value: '${stats.totalScore}',
                        color: AppTheme.saffron,
                      ),
                      _StatItem(
                        icon: Icons.emoji_events,
                        label: 'Best',
                        value: '${stats.bestStreak}',
                        color: AppTheme.greenAccent,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(QuizProvider quizProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Failed to load quiz',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            quizProvider.error ?? '',
            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.mediumGray),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => quizProvider.fetchQuiz(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizQuestion(QuizProvider quizProvider) {
    final question = quizProvider.currentQuestion!;
    final index = quizProvider.currentQuestionIndex;
    final total = quizProvider.totalQuestions;
    final hasAnswered = quizProvider.hasAnsweredCurrent;
    final selectedAnswer =
        quizProvider.selectedAnswers[index];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: quizProvider.progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.saffron),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${index + 1}/$total',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.saffron,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Score
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                'Score: ${quizProvider.score}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.mediumGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Question card
          Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      question.question,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Options
                    Expanded(
                      child: ListView.builder(
                        itemCount: question.options.length,
                        itemBuilder: (context, optIndex) {
                          final option = question.options[optIndex];
                          final letter = String.fromCharCode(65 + optIndex);
                          final isSelected = selectedAnswer == optIndex;
                          final isCorrect = optIndex == question.correctIndex;
                          final isEliminated = quizProvider.hintUsed &&
                              quizProvider.getHintElimination() == optIndex;

                          Color bgColor;
                          Color borderColor;
                          Color textColor;

                          if (hasAnswered) {
                            if (isCorrect) {
                              bgColor = AppTheme.greenAccent.withOpacity(0.15);
                              borderColor = AppTheme.greenAccent;
                              textColor = AppTheme.greenAccent;
                            } else if (isSelected && !isCorrect) {
                              bgColor = Colors.red.withOpacity(0.15);
                              borderColor = Colors.red;
                              textColor = Colors.red;
                            } else {
                              bgColor = Colors.grey.shade50;
                              borderColor = Colors.grey.shade200;
                              textColor = AppTheme.mediumGray;
                            }
                          } else {
                            bgColor = Colors.white;
                            borderColor = Colors.grey.shade300;
                            textColor = AppTheme.darkGray;
                          }

                          if (isEliminated && !hasAnswered) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Opacity(
                                opacity: 0.3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(letter,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey,
                                              )),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: hasAnswered
                                  ? null
                                  : () =>
                                      quizProvider.answerQuestion(optIndex),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: borderColor,
                                    width: isSelected || (hasAnswered && isCorrect) ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: hasAnswered
                                            ? (isCorrect
                                                ? AppTheme.greenAccent
                                                    .withOpacity(0.2)
                                                : (isSelected
                                                    ? Colors.red
                                                        .withOpacity(0.2)
                                                    : Colors.grey.shade100))
                                            : AppTheme.saffron
                                                .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: hasAnswered
                                            ? (isCorrect
                                                ? const Icon(Icons.check,
                                                    size: 16,
                                                    color: AppTheme
                                                        .greenAccent)
                                                : (isSelected
                                                    ? const Icon(Icons.close,
                                                        size: 16,
                                                        color: Colors.red)
                                                    : Text(letter,
                                                        style: GoogleFonts
                                                            .poppins(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: textColor,
                                                        ))))
                                            : Text(letter,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.saffron,
                                                )),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Explanation
                    if (hasAnswered && question.explanation != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb,
                                color: Colors.blue.shade400, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                question.explanation!,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Bottom action row
          Row(
            children: [
              // Hint button
              if (!hasAnswered && !quizProvider.hintUsed)
                OutlinedButton.icon(
                  onPressed: () {
                    _adService.showRewarded(
                      onReward: (_) {
                        quizProvider.useHint();
                      },
                    ).then((shown) {
                      if (!shown) {
                        // If no ad available, give hint anyway for dev
                        quizProvider.useHint();
                      }
                    });
                  },
                  icon: const Icon(Icons.lightbulb_outline, size: 18),
                  label: Text(
                    'Hint (Ad)',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.saffron,
                    side: const BorderSide(color: AppTheme.saffron),
                  ),
                ),
              const Spacer(),
              // Next button
              if (hasAnswered)
                ElevatedButton(
                  onPressed: () => quizProvider.nextQuestion(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.saffron,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    index < total - 1 ? 'Next Question' : 'See Results',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResults(QuizProvider quizProvider) {
    final score = quizProvider.score;
    final total = quizProvider.totalQuestions;
    final percentage = total > 0 ? (score / total * 100).round() : 0;

    String emoji;
    String message;
    if (percentage >= 80) {
      emoji = '🏆';
      message = 'Excellent! You\'re a news expert!';
    } else if (percentage >= 60) {
      emoji = '👏';
      message = 'Great job! Keep reading!';
    } else if (percentage >= 40) {
      emoji = '💪';
      message = 'Good effort! Read more to improve!';
    } else {
      emoji = '📖';
      message = 'Keep reading BharatBrief daily!';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'Quiz Complete!',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Score circle
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.saffron, AppTheme.saffronLight],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.saffron.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$score/$total',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Share.share(quizProvider.getShareText());
                },
                icon: const Icon(Icons.share),
                label: Text(
                  'Share on WhatsApp',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  final uid = context.read<UserProvider>().user.uid;
                  quizProvider.submitQuiz(uid).then((_) {
                    final result = quizProvider.result;
                    if (result != null) {
                      context.read<UserProvider>().updateQuizScore(
                            result.score,
                            result.streak,
                          );
                    }
                  });
                  quizProvider.resetQuiz();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.saffron,
                  side: const BorderSide(color: AppTheme.saffron),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.mediumGray,
          ),
        ),
      ],
    );
  }
}
