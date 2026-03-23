class AppConstants {
  AppConstants._();

  // API Configuration
  // For macOS/iOS simulator: localhost. For Android emulator: 10.0.2.2. For physical device: your machine IP.
  static const String apiBaseUrl = 'https://bharatbrief-production.up.railway.app/api';
  static const int apiTimeout = 15000;
  static const int articlesPerPage = 50;

  // AdMob Test IDs (replace with real IDs before production)
  static const String adMobAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String nativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  // Ad frequency
  static const int interstitialCardInterval = 7;
  static const int pollCardInterval = 10;

  // Firebase collections
  static const String usersCollection = 'users';
  static const String articlesCollection = 'articles';
  static const String quizzesCollection = 'quizzes';

  // Supported languages with native names
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'native': 'English', 'script': 'Latn'},
    {'code': 'hi', 'name': 'Hindi', 'native': '\u0939\u093F\u0928\u094D\u0926\u0940', 'script': 'Deva'},
    {'code': 'bn', 'name': 'Bengali', 'native': '\u09AC\u09BE\u0982\u09B2\u09BE', 'script': 'Beng'},
    {'code': 'te', 'name': 'Telugu', 'native': '\u0C24\u0C46\u0C32\u0C41\u0C17\u0C41', 'script': 'Telu'},
    {'code': 'mr', 'name': 'Marathi', 'native': '\u092E\u0930\u093E\u0920\u0940', 'script': 'Deva'},
    {'code': 'ta', 'name': 'Tamil', 'native': '\u0BA4\u0BAE\u0BBF\u0BB4\u0BCD', 'script': 'Taml'},
    {'code': 'gu', 'name': 'Gujarati', 'native': '\u0A97\u0AC1\u0A9C\u0AB0\u0ABE\u0AA4\u0AC0', 'script': 'Gujr'},
    {'code': 'kn', 'name': 'Kannada', 'native': '\u0C95\u0CA8\u0CCD\u0CA8\u0CA1', 'script': 'Knda'},
    {'code': 'ml', 'name': 'Malayalam', 'native': '\u0D2E\u0D32\u0D2F\u0D3E\u0D33\u0D02', 'script': 'Mlym'},
    {'code': 'pa', 'name': 'Punjabi', 'native': '\u0A2A\u0A70\u0A1C\u0A3E\u0A2C\u0A40', 'script': 'Guru'},
    {'code': 'or', 'name': 'Odia', 'native': '\u0B13\u0B21\u0B3C\u0B3F\u0B06', 'script': 'Orya'},
    {'code': 'as', 'name': 'Assamese', 'native': '\u0985\u09B8\u09AE\u09C0\u09AF\u09BC\u09BE', 'script': 'Beng'},
    {'code': 'ur', 'name': 'Urdu', 'native': '\u0627\u0631\u062F\u0648', 'script': 'Arab'},
  ];

  // News categories
  static const List<Map<String, dynamic>> categories = [
    {'id': 'all', 'name': 'All', 'icon': 'all_inclusive'},
    {'id': 'national', 'name': 'National', 'icon': 'flag'},
    {'id': 'my_state', 'name': 'My State', 'icon': 'location_on'},
    {'id': 'world', 'name': 'World', 'icon': 'public'},
    {'id': 'sports', 'name': 'Sports', 'icon': 'sports_cricket'},
    {'id': 'tech', 'name': 'Tech', 'icon': 'computer'},
    {'id': 'business', 'name': 'Business', 'icon': 'business'},
    {'id': 'entertainment', 'name': 'Entertainment', 'icon': 'movie'},
    {'id': 'science', 'name': 'Science', 'icon': 'science'},
    {'id': 'health', 'name': 'Health', 'icon': 'health_and_safety'},
  ];

  // Indian states
  static const List<Map<String, String>> indianStates = [
    {'code': 'AP', 'name': 'Andhra Pradesh'},
    {'code': 'AR', 'name': 'Arunachal Pradesh'},
    {'code': 'AS', 'name': 'Assam'},
    {'code': 'BR', 'name': 'Bihar'},
    {'code': 'CG', 'name': 'Chhattisgarh'},
    {'code': 'GA', 'name': 'Goa'},
    {'code': 'GJ', 'name': 'Gujarat'},
    {'code': 'HR', 'name': 'Haryana'},
    {'code': 'HP', 'name': 'Himachal Pradesh'},
    {'code': 'JH', 'name': 'Jharkhand'},
    {'code': 'KA', 'name': 'Karnataka'},
    {'code': 'KL', 'name': 'Kerala'},
    {'code': 'MP', 'name': 'Madhya Pradesh'},
    {'code': 'MH', 'name': 'Maharashtra'},
    {'code': 'MN', 'name': 'Manipur'},
    {'code': 'ML', 'name': 'Meghalaya'},
    {'code': 'MZ', 'name': 'Mizoram'},
    {'code': 'NL', 'name': 'Nagaland'},
    {'code': 'OD', 'name': 'Odisha'},
    {'code': 'PB', 'name': 'Punjab'},
    {'code': 'RJ', 'name': 'Rajasthan'},
    {'code': 'SK', 'name': 'Sikkim'},
    {'code': 'TN', 'name': 'Tamil Nadu'},
    {'code': 'TS', 'name': 'Telangana'},
    {'code': 'TR', 'name': 'Tripura'},
    {'code': 'UP', 'name': 'Uttar Pradesh'},
    {'code': 'UK', 'name': 'Uttarakhand'},
    {'code': 'WB', 'name': 'West Bengal'},
    {'code': 'AN', 'name': 'Andaman & Nicobar'},
    {'code': 'CH', 'name': 'Chandigarh'},
    {'code': 'DN', 'name': 'Dadra & Nagar Haveli and Daman & Diu'},
    {'code': 'DL', 'name': 'Delhi'},
    {'code': 'JK', 'name': 'Jammu & Kashmir'},
    {'code': 'LA', 'name': 'Ladakh'},
    {'code': 'LD', 'name': 'Lakshadweep'},
    {'code': 'PY', 'name': 'Puducherry'},
  ];

  // Reading modes
  static const Map<String, String> readingModes = {
    'quick': 'Quick Read',
    'deep': 'Deep Dive',
    'feelgood': 'Feel Good',
  };

  // Font sizes
  static const Map<String, double> fontSizes = {
    'small': 0.85,
    'medium': 1.0,
    'large': 1.2,
  };
}
