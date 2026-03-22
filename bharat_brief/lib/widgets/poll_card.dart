import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class PollCard extends StatefulWidget {
  final String question;
  final List<String> options;
  final Function(int)? onVote;

  const PollCard({
    super.key,
    required this.question,
    required this.options,
    this.onVote,
  });

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  bool _hasVoted = false;
  late AnimationController _animController;

  // Simulated vote percentages (in production, these come from the API)
  final List<double> _mockPercentages = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _generateMockPercentages();
  }

  void _generateMockPercentages() {
    // Generate random percentages that sum to 100
    double remaining = 100.0;
    for (int i = 0; i < widget.options.length - 1; i++) {
      final val =
          (remaining / (widget.options.length - i) * (0.5 + 1.0 * 0.5))
              .roundToDouble();
      _mockPercentages.add(val.clamp(5, remaining - 5));
      remaining -= _mockPercentages.last;
    }
    _mockPercentages.add(remaining);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _vote(int index) {
    if (_hasVoted) return;
    setState(() {
      _selectedIndex = index;
      _hasVoted = true;
    });
    _animController.forward();
    widget.onVote?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.saffron.withOpacity(0.05),
            AppTheme.greenAccent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.saffron.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Poll badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.saffron.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.poll, color: AppTheme.saffron, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Quick Poll',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.saffron,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Question
          Text(
            widget.question,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          // Options
          ...widget.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _selectedIndex == index;
            final percentage =
                index < _mockPercentages.length ? _mockPercentages[index] : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _vote(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _hasVoted
                        ? (isSelected
                            ? AppTheme.saffron.withOpacity(0.1)
                            : Colors.grey.shade50)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hasVoted
                          ? (isSelected ? AppTheme.saffron : Colors.grey.shade200)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Percentage bar (shown after voting)
                      if (_hasVoted)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: AnimatedBuilder(
                            listenable: _animController,
                            builder: (context, child) {
                              return Container(
                                width: (MediaQuery.of(context).size.width -
                                        96) *
                                    (percentage / 100) *
                                    _animController.value,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.saffron.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            },
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppTheme.saffron
                                    : AppTheme.darkGray,
                              ),
                            ),
                          ),
                          if (_hasVoted)
                            Text(
                              '${percentage.toInt()}%',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppTheme.saffron
                                    : AppTheme.mediumGray,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_hasVoted)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '1.2K votes',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.mediumGray,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }

  Animation<double> get animation => listenable as Animation<double>;
}
