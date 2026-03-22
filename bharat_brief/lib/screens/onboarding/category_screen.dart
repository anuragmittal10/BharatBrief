import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/article_provider.dart';
import '../home/home_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String selectedLanguage;
  final String selectedState;

  const CategoryScreen({
    super.key,
    required this.selectedLanguage,
    required this.selectedState,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _selectedCategories = {};
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  static const _categoryIcons = <String, IconData>{
    'national': Icons.flag,
    'my_state': Icons.location_on,
    'world': Icons.public,
    'sports': Icons.sports_cricket,
    'tech': Icons.computer,
    'business': Icons.business,
    'entertainment': Icons.movie,
    'science': Icons.science,
    'health': Icons.health_and_safety,
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _selectableCategories {
    return AppConstants.categories
        .where((c) => c['id'] != 'all')
        .toList();
  }

  void _onGetStarted() async {
    final userProvider = context.read<UserProvider>();
    final articleProvider = context.read<ArticleProvider>();

    await userProvider.registerUser(
      language: widget.selectedLanguage,
      state: widget.selectedState,
      categories: _selectedCategories.toList(),
    );

    articleProvider.changeLanguage(widget.selectedLanguage);
    if (widget.selectedState.isNotEmpty) {
      articleProvider.changeState(widget.selectedState);
    }

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _selectedCategories.length >= 3;

    return Scaffold(
      backgroundColor: AppTheme.indianWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.saffron),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What interests you?',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose at least 3 categories to personalize your feed',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.mediumGray,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isValid
                      ? AppTheme.greenAccent.withOpacity(0.1)
                      : AppTheme.saffron.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedCategories.length} selected${isValid ? ' - Ready!' : ' (min 3)'}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isValid ? AppTheme.greenAccent : AppTheme.saffron,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Category grid
              Expanded(
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _selectableCategories.length,
                  itemBuilder: (context, index) {
                    final cat = _selectableCategories[index];
                    final id = cat['id'] as String;
                    final name = cat['name'] as String;
                    final isSelected = _selectedCategories.contains(id);
                    final color = AppTheme.categoryColors[id] ??
                        AppTheme.saffron;
                    final icon = _categoryIcons[id] ?? Icons.article;

                    return _CategoryCard(
                      name: name,
                      icon: icon,
                      color: color,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedCategories.remove(id);
                          } else {
                            _selectedCategories.add(id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              // Get Started button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isValid ? _onGetStarted : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.saffron,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: isValid ? 3 : 0,
                    ),
                    child: context.watch<UserProvider>().isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Get Started',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : AppTheme.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.check_circle,
                  color: color,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
