import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/article_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/ad_service.dart';
import '../../widgets/news_card.dart';
import '../../widgets/shimmer_card.dart';

class SwipeFeed extends StatefulWidget {
  const SwipeFeed({super.key});

  @override
  State<SwipeFeed> createState() => _SwipeFeedState();
}

class _SwipeFeedState extends State<SwipeFeed> {
  final PageController _pageController = PageController();
  final AdService _adService = AdService();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initAds();
  }

  Future<void> _initAds() async {
    try {
      await _adService.initialize();
    } catch (_) {
      // Ads may fail to initialize in dev/test environments
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _adService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final articleProvider = context.watch<ArticleProvider>();
    final articles = articleProvider.articles;
    final isLoading = articleProvider.isLoading;
    final error = articleProvider.error;

    if (isLoading && articles.isEmpty) {
      return const ShimmerCard();
    }

    if (error != null && articles.isEmpty) {
      return _buildErrorState(error, articleProvider);
    }

    if (articles.isEmpty) {
      return _buildEmptyState();
    }

    // Add 1 for the "all caught up" card at the end
    final itemCount = articles.length + (articleProvider.hasMore ? 0 : 1);

    return Container(
      color: const Color(0xFFFAFAFA),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: itemCount,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              _adService.onCardViewed();

              // Load more when near the end
              if (index >= articles.length - 3 && articleProvider.hasMore) {
                articleProvider.fetchArticles();
              }
            },
            itemBuilder: (context, index) {
              if (index >= articles.length) {
                return _buildAllCaughtUp();
              }

              return NewsCard(
                article: articles[index],
                index: index,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, ArticleProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.fetchArticles(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.saffron,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No articles yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for the latest news',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllCaughtUp() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.greenAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.greenAccent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'You\'re all caught up!',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ve read all the latest news.\nCheck back later for more updates.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.mediumGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () {
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
            icon: const Icon(Icons.arrow_upward),
            label: const Text('Back to top'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.saffron,
              side: const BorderSide(color: AppTheme.saffron),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
