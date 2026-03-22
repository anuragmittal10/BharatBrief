import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/article.dart';
import '../../providers/article_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/date_utils.dart';
import '../../widgets/shimmer_card.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bookmarks',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.saffron,
          ),
        ),
        centerTitle: true,
      ),
      body: const _BookmarksList(),
    );
  }
}

class _BookmarksList extends StatelessWidget {
  const _BookmarksList();

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final articleProvider = context.watch<ArticleProvider>();
    final bookmarkIds = userProvider.bookmarks;
    final lang = userProvider.language;

    if (bookmarkIds.isEmpty) {
      return _buildEmptyState();
    }

    // Get bookmarked articles from the article provider
    final bookmarkedArticles = bookmarkIds
        .map((id) => articleProvider.getArticleById(id))
        .where((a) => a != null)
        .cast<Article>()
        .toList();

    if (bookmarkedArticles.isEmpty && bookmarkIds.isNotEmpty) {
      // Articles not loaded yet, show IDs with placeholder
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: bookmarkIds.length,
        itemBuilder: (context, index) => const ShimmerListItem(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: bookmarkedArticles.length,
      itemBuilder: (context, index) {
        final article = bookmarkedArticles[index];
        return _BookmarkTile(
          article: article,
          lang: lang,
          onDismissed: () {
            userProvider.removeBookmark(article.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Bookmark removed',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    userProvider.addBookmark(article.id);
                  },
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
              child: Icon(
                Icons.bookmark_border,
                size: 64,
                color: AppTheme.saffron.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No bookmarks yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save articles you want to read later\nby tapping the bookmark icon',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.mediumGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final Article article;
  final String lang;
  final VoidCallback onDismissed;

  const _BookmarkTile({
    required this.article,
    required this.lang,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final headline = article.getHeadline(lang);
    final categoryColor =
        AppTheme.categoryColors[article.category] ?? AppTheme.saffron;

    return Dismissible(
      key: Key(article.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Could navigate to full article view
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: article.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: article.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image,
                                  color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.article,
                              color: categoryColor,
                              size: 32,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            article.category
                                .toUpperCase()
                                .replaceAll('_', ' '),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: categoryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Headline
                        Text(
                          headline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Source and time
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                article.source,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppTheme.mediumGray,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              AppDateUtils.timeAgo(article.publishedAt),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
