/// Stub AdService — ads disabled until google_mobile_ads is configured.
/// To enable ads: uncomment google_mobile_ads in pubspec.yaml and replace this file.
class AdService {
  int _cardViewCount = 0;

  bool get isBannerAdLoaded => false;
  bool get isRewardedAdReady => false;

  Future<void> initialize() async {}

  void loadBannerAd({Function(bool)? onLoaded}) {
    onLoaded?.call(false);
  }

  void onCardViewed() {
    _cardViewCount++;
  }

  Future<void> showInterstitial() async {}

  Future<bool> showRewarded({
    required void Function(dynamic reward) onReward,
  }) async {
    // Give reward directly when ads are disabled
    onReward(null);
    return true;
  }

  void dispose() {}
}
