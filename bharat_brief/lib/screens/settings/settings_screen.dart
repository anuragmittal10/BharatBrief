import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/article_provider.dart';
import '../onboarding/language_screen.dart';
import '../onboarding/state_screen.dart';
import '../onboarding/category_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.saffron,
          ),
        ),
        centerTitle: true,
      ),
      body: const _SettingsList(),
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final userProvider = context.watch<UserProvider>();

    // Find current language name
    final currentLangName = AppConstants.supportedLanguages
        .firstWhere(
          (l) => l['code'] == userProvider.language,
          orElse: () => {'name': 'English', 'native': 'English', 'code': 'en'},
        );

    // Find current state name
    String currentStateName = 'Not selected';
    if (userProvider.state.isNotEmpty) {
      final stateData = AppConstants.indianStates.firstWhere(
        (s) => s['code'] == userProvider.state,
        orElse: () => {'name': userProvider.state, 'code': userProvider.state},
      );
      currentStateName = stateData['name'] ?? userProvider.state;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Preferences section
        _SectionHeader(title: 'Preferences'),
        _SettingsTile(
          icon: Icons.language,
          title: 'Language',
          subtitle:
              '${currentLangName['native']} (${currentLangName['name']})',
          onTap: () => _showLanguageDialog(context),
        ),
        _SettingsTile(
          icon: Icons.location_on_outlined,
          title: 'State / City',
          subtitle: currentStateName,
          onTap: () => _showStateDialog(context),
        ),
        _SettingsTile(
          icon: Icons.category_outlined,
          title: 'Categories',
          subtitle: '${userProvider.categories.length} selected',
          onTap: () => _showCategoryDialog(context),
        ),
        _SettingsTile(
          icon: settings.readingModeIcon,
          title: 'Reading Mode',
          subtitle: settings.readingModeLabel,
          onTap: () => _showReadingModeDialog(context),
        ),

        const SizedBox(height: 8),
        // Display section
        _SectionHeader(title: 'Display'),
        _SettingsTile(
          icon: Icons.text_fields,
          title: 'Font Size',
          subtitle: settings.fontSize[0].toUpperCase() +
              settings.fontSize.substring(1),
          onTap: () => _showFontSizeDialog(context),
        ),
        _SwitchTile(
          icon: Icons.dark_mode_outlined,
          title: 'Dark Mode',
          value: settings.themeMode == ThemeMode.dark,
          onChanged: (val) => settings.setThemeMode(
              val ? ThemeMode.dark : ThemeMode.light),
        ),
        _SwitchTile(
          icon: Icons.data_saver_on_outlined,
          title: 'Data Saver',
          subtitle: 'Reduce data usage by loading lower quality images',
          value: settings.dataSaver,
          onChanged: (val) => settings.setDataSaver(val),
        ),

        const SizedBox(height: 8),
        // Notifications section
        _SectionHeader(title: 'Notifications'),
        _SwitchTile(
          icon: Icons.wb_sunny_outlined,
          title: 'Morning Digest',
          subtitle: 'Daily summary at 8 AM',
          value: settings.notifMorning,
          onChanged: (val) => settings.setNotifMorning(val),
        ),
        _SwitchTile(
          icon: Icons.flash_on,
          title: 'Breaking News',
          subtitle: 'Get notified for breaking news',
          value: settings.notifBreaking,
          onChanged: (val) => settings.setNotifBreaking(val),
        ),
        _SwitchTile(
          icon: Icons.quiz_outlined,
          title: 'Quiz Reminders',
          subtitle: 'Daily quiz reminder at 8 PM',
          value: settings.notifQuiz,
          onChanged: (val) => settings.setNotifQuiz(val),
        ),

        const SizedBox(height: 8),
        // About section
        _SectionHeader(title: 'About'),
        _SettingsTile(
          icon: Icons.info_outline,
          title: 'About BharatBrief',
          onTap: () => _showAboutDialog(context),
        ),
        _SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () async {
            final uri = Uri.parse('https://bharatbrief.com/privacy');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
        _SettingsTile(
          icon: Icons.star_border,
          title: 'Rate App',
          onTap: () async {
            final uri = Uri.parse(
                'https://play.google.com/store/apps/details?id=com.bharatbrief.bharat_brief');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
        _SettingsTile(
          icon: Icons.share_outlined,
          title: 'Share App',
          onTap: () {
            Share.share(
              'Check out BharatBrief - Read news in your language!\n'
              'https://bharatbrief.com/download',
            );
          },
        ),

        const SizedBox(height: 24),
        Center(
          child: Text(
            'BharatBrief v1.0.0',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.mediumGray,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final articleProvider = context.read<ArticleProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Select Language',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: AppConstants.supportedLanguages.length,
                    itemBuilder: (context, index) {
                      final lang = AppConstants.supportedLanguages[index];
                      final isSelected =
                          lang['code'] == userProvider.language;
                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.saffron.withOpacity(0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              lang['native']!.substring(0, 1),
                              style: GoogleFonts.notoSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppTheme.saffron
                                    : AppTheme.darkGray,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          lang['native']!,
                          style: GoogleFonts.notoSans(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.saffron
                                : null,
                          ),
                        ),
                        subtitle: Text(lang['name']!),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: AppTheme.saffron)
                            : null,
                        onTap: () {
                          userProvider.setLanguage(lang['code']!);
                          articleProvider.changeLanguage(lang['code']!);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStateDialog(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final articleProvider = context.read<ArticleProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Select State',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: AppConstants.indianStates.length,
                    itemBuilder: (context, index) {
                      final state = AppConstants.indianStates[index];
                      final isSelected =
                          state['code'] == userProvider.state;
                      return ListTile(
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: isSelected
                              ? AppTheme.saffron
                              : AppTheme.mediumGray,
                        ),
                        title: Text(
                          state['name']!,
                          style: GoogleFonts.poppins(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.saffron
                                : null,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: AppTheme.saffron)
                            : null,
                        onTap: () {
                          userProvider.setUserState(state['code']!);
                          articleProvider.changeState(state['code']!);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCategoryDialog(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final selectedCats = Set<String>.from(userProvider.categories);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Manage Categories',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.categories
                        .where((c) => c['id'] != 'all')
                        .map((cat) {
                      final id = cat['id'] as String;
                      final name = cat['name'] as String;
                      final isSelected = selectedCats.contains(id);
                      final color =
                          AppTheme.categoryColors[id] ?? AppTheme.saffron;

                      return FilterChip(
                        label: Text(name),
                        selected: isSelected,
                        selectedColor: color.withOpacity(0.2),
                        checkmarkColor: color,
                        labelStyle: GoogleFonts.poppins(
                          color: isSelected ? color : AppTheme.darkGray,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              selectedCats.add(id);
                            } else if (selectedCats.length > 1) {
                              selectedCats.remove(id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        userProvider.setCategories(selectedCats.toList());
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReadingModeDialog(BuildContext context) {
    final settings = context.read<SettingsProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reading Mode',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _ReadingModeTile(
                icon: Icons.flash_on,
                title: 'Quick Read',
                subtitle: '60-word summaries for fast consumption',
                isSelected: settings.readingMode == 'quick',
                onTap: () {
                  settings.setReadingMode('quick');
                  Navigator.pop(context);
                },
              ),
              _ReadingModeTile(
                icon: Icons.menu_book,
                title: 'Deep Dive',
                subtitle: 'Detailed summaries with more context',
                isSelected: settings.readingMode == 'deep',
                onTap: () {
                  settings.setReadingMode('deep');
                  Navigator.pop(context);
                },
              ),
              _ReadingModeTile(
                icon: Icons.favorite,
                title: 'Feel Good',
                subtitle: 'Only positive and uplifting stories',
                isSelected: settings.readingMode == 'feelgood',
                onTap: () {
                  settings.setReadingMode('feelgood');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showFontSizeDialog(BuildContext context) {
    final settings = context.read<SettingsProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Font Size',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...['small', 'medium', 'large'].map((size) {
                final isSelected = settings.fontSize == size;
                final label =
                    size[0].toUpperCase() + size.substring(1);
                double fontSize;
                switch (size) {
                  case 'small':
                    fontSize = 14;
                    break;
                  case 'large':
                    fontSize = 20;
                    break;
                  default:
                    fontSize = 16;
                }

                return ListTile(
                  title: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected ? AppTheme.saffron : null,
                    ),
                  ),
                  subtitle: Text(
                    'Sample text preview',
                    style: GoogleFonts.poppins(fontSize: fontSize - 2),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: AppTheme.saffron)
                      : null,
                  onTap: () {
                    settings.setFontSize(size);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'BharatBrief',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppTheme.saffron,
            ),
          ),
          content: Text(
            'BharatBrief is an AI-powered multilingual news aggregator '
            'that delivers 60-word news summaries in 13 Indian languages.\n\n'
            'Stay informed with hyperlocal news, daily quizzes, and '
            'audio summaries - all designed for the busy Indian reader.\n\n'
            'Version 1.0.0',
            style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(color: AppTheme.saffron),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.saffron,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.saffron.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.saffron, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.mediumGray,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppTheme.mediumGray),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.saffron.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.saffron, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.mediumGray,
              ),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.saffron,
    );
  }
}

class _ReadingModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReadingModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.saffron.withOpacity(0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppTheme.saffron : AppTheme.mediumGray,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppTheme.saffron : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.mediumGray),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppTheme.saffron)
          : null,
      onTap: onTap,
    );
  }
}
