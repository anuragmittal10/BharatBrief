import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/article_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/language_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize storage
  final storageService = StorageService();
  await storageService.init();

  // Initialize API service
  final apiService = ApiService();

  runApp(
    BharatBriefApp(
      storageService: storageService,
      apiService: apiService,
    ),
  );
}

class BharatBriefApp extends StatelessWidget {
  final StorageService storageService;
  final ApiService apiService;

  const BharatBriefApp({
    super.key,
    required this.storageService,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider(
            storage: storageService,
            api: apiService,
          )..loadFromStorage(),
        ),
        ChangeNotifierProvider(
          create: (_) => ArticleProvider(
            api: apiService,
            storage: storageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => QuizProvider(api: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storage: storageService)
            ..loadFromStorage(),
        ),
      ],
      child: const _AppWithTheme(),
    );
  }
}

class _AppWithTheme extends StatelessWidget {
  const _AppWithTheme();

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final userProvider = context.watch<UserProvider>();

    // Determine text direction for RTL support (Urdu)
    final isRtl = userProvider.language == 'ur';

    // Check if this is first launch
    final isFirstLaunch = userProvider.user.uid.isEmpty;

    return MaterialApp(
      title: 'BharatBrief',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsProvider.themeMode,
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(settingsProvider.fontScale),
          ),
          child: Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: isFirstLaunch ? const LanguageScreen() : const HomeScreen(),
    );
  }
}
