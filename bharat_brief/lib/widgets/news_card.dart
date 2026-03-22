import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/article.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart';
import '../utils/date_utils.dart';

class NewsCard extends StatefulWidget {
  final Article article;
  final int index;

  const NewsCard({
    super.key,
    required this.article,
    required this.index,
  });

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final AudioService _audioService = AudioService();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Color get _moodColor {
    switch (widget.article.moodTag) {
      case 'positive':
        return AppTheme.moodPositive;
      case 'negative':
        return AppTheme.moodNegative;
      default:
        return AppTheme.moodNeutral;
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  Color get _categoryColor {
    return AppTheme.categoryColors[widget.article.category] ?? AppTheme.saffron;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final lang = userProvider.language;
    final headline = widget.article.getHeadline(lang);
    final summary = widget.article.getSummary(lang);
    final isBookmarked = userProvider.isBookmarked(widget.article.id);
    final fontScale = settingsProvider.fontScale;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: const Color(0xFFFAFAFA),
          child: Column(
            children: [
              // Top ~40%: Image
              Expanded(
                flex: 4,
                child: _buildImageSection(headline),
              ),
              // Bottom ~60%: Content
              Expanded(
                flex: 6,
                child: _buildContentSection(
                  headline: headline,
                  summary: summary,
                  isBookmarked: isBookmarked,
                  fontScale: fontScale,
                  userProvider: userProvider,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(String headline) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image - full bleed, no rounded corners
        widget.article.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: widget.article.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.saffron,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _categoryColor.withOpacity(0.8),
                      _categoryColor.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.article,
                    size: 64,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
        // Gradient overlay at bottom of image
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
        ),
        // Category badge
        Positioned(
          top: 12,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _categoryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.article.category.toUpperCase().replaceAll('_', ' '),
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        // Mood indicator
        Positioned(
          top: 14,
          right: 14,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _moodColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
        // Source and time on gradient
        Positioned(
          bottom: 10,
          left: 14,
          right: 14,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.article.source,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_formatDate(widget.article.publishedAt)}  •  ${AppDateUtils.timeAgo(widget.article.publishedAt)}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
        // Trending badge
        if (widget.article.isTrending)
          Positioned(
            top: 12,
            right: 30,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up,
                      color: Colors.white, size: 12),
                  const SizedBox(width: 3),
                  Text(
                    'TRENDING',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContentSection({
    required String headline,
    required String summary,
    required bool isBookmarked,
    required double fontScale,
    required UserProvider userProvider,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline
          Text(
            headline,
            style: GoogleFonts.poppins(
              fontSize: 20 * fontScale,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: const Color(0xFF1A1A2E),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Summary
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                summary,
                style: GoogleFonts.poppins(
                  fontSize: 15 * fontScale,
                  height: 1.7,
                  color: const Color(0xFF4A4A5A),
                ),
              ),
            ),
          ),
          // Divider above action bar
          Divider(
            color: Colors.grey.shade200,
            height: 1,
          ),
          const SizedBox(height: 6),
          // Action bar pinned at bottom
          _buildActionBar(isBookmarked, userProvider),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildActionBar(bool isBookmarked, UserProvider userProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Bookmark
        _ActionButton(
          icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          label: 'Save',
          color: isBookmarked ? AppTheme.saffron : null,
          onTap: () {
            if (isBookmarked) {
              userProvider.removeBookmark(widget.article.id);
            } else {
              userProvider.addBookmark(widget.article.id);
            }
          },
        ),
        // Share
        _ActionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: () {
            final lang = userProvider.language;
            Share.share(
              '${widget.article.getHeadline(lang)}\n\n'
              '${widget.article.getSummary(lang)}\n\n'
              'Read more: ${widget.article.originalLink}\n\n'
              'via BharatBrief',
            );
          },
        ),
        // Listen
        _ActionButton(
          icon: _isListening ? Icons.stop : Icons.headphones_outlined,
          label: _isListening ? 'Stop' : 'Listen',
          color: _isListening ? AppTheme.saffron : null,
          onTap: () {
            final ttsUrl = widget.article
                .getTtsUrl(userProvider.language);
            if (ttsUrl != null && ttsUrl.isNotEmpty) {
              if (_isListening) {
                _audioService.stop();
              } else {
                _audioService.play(ttsUrl,
                    articleId: widget.article.id);
              }
              setState(() {
                _isListening = !_isListening;
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Audio not available for this article',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
        ),
        // Read full article
        _ActionButton(
          icon: Icons.open_in_new,
          label: 'Full',
          onTap: () async {
            final uri = Uri.tryParse(widget.article.originalLink);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = const Color(0xFF8E8E93);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? defaultColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: color ?? defaultColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
