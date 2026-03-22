import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/article_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/connectivity_utils.dart';
import '../../widgets/category_tabs.dart';
import '../../widgets/language_switcher.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../quiz/quiz_screen.dart';
import '../settings/settings_screen.dart';
import '../offline/offline_screen.dart';
import 'swipe_feed.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final ConnectivityUtils _connectivity = ConnectivityUtils();
  bool _showOfflineBanner = false;

  @override
  void initState() {
    super.initState();
    _connectivity.initialize();
    _connectivity.connectionStream.listen((connected) {
      setState(() {
        _showOfflineBanner = !connected;
      });
      if (connected) {
        context.read<ArticleProvider>().fetchArticles(refresh: true);
      }
    });

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final articleProvider = context.read<ArticleProvider>();
      final userProvider = context.read<UserProvider>();
      articleProvider.changeLanguage(userProvider.language);
      if (userProvider.state.isNotEmpty) {
        articleProvider.changeState(userProvider.state);
      }
      articleProvider.fetchArticles(refresh: true);
      articleProvider.fetchTrending();
    });
  }

  @override
  void dispose() {
    _connectivity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _currentIndex == 0 ? _buildAppBar() : null,
      body: Column(
        children: [
          if (_showOfflineBanner) _buildOfflineBanner(),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.small(
              onPressed: () {
                settingsProvider.cycleReadingMode();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(settingsProvider.readingModeIcon,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(settingsProvider.readingModeLabel),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              backgroundColor: AppTheme.saffron,
              child: Icon(settingsProvider.readingModeIcon),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'BharatBrief',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: AppTheme.saffron,
        ),
      ),
      actions: [
        const LanguageSwitcher(),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchDialog(),
        ),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: Colors.orange.shade700,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            'You\'re offline - showing cached articles',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const _HomeFeed();
      case 1:
        return const QuizScreen();
      case 2:
        return const BookmarksScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const _HomeFeed();
    }
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.quiz_outlined),
          activeIcon: Icon(Icons.quiz),
          label: 'Quiz',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_outline),
          activeIcon: Icon(Icons.bookmark),
          label: 'Bookmarks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  void _showSearchDialog() {
    showSearch(
      context: context,
      delegate: _ArticleSearchDelegate(),
    );
  }
}

class _HomeFeed extends StatelessWidget {
  const _HomeFeed();

  @override
  Widget build(BuildContext context) {
    final articleProvider = context.watch<ArticleProvider>();
    final isOffline = articleProvider.isOffline;

    if (isOffline && articleProvider.articles.isEmpty) {
      return const OfflineScreen();
    }

    return Column(
      children: [
        const CategoryTabs(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => articleProvider.fetchArticles(refresh: true),
            color: AppTheme.saffron,
            child: const SwipeFeed(),
          ),
        ),
      ],
    );
  }
}

class _ArticleSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Search news...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.poppins(
          color: AppTheme.mediumGray,
          fontSize: 16,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Search for news articles',
              style: GoogleFonts.poppins(
                color: AppTheme.mediumGray,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final articleProvider = context.read<ArticleProvider>();
    final results = articleProvider.searchArticles(query);
    final lang = articleProvider.currentLanguage;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              style: GoogleFonts.poppins(
                color: AppTheme.mediumGray,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final article = results[index];
        return ListTile(
          leading: article.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    article.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.article, color: Colors.grey),
                    ),
                  ),
                )
              : Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.article, color: Colors.grey),
                ),
          title: Text(
            article.getHeadline(lang),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            article.source,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.mediumGray,
            ),
          ),
          onTap: () {
            close(context, article.id);
          },
        );
      },
    );
  }
}
