import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._();
  static AdService get instance => _instance;
  AdService._();

  int _recordCount = 0;
  int _detailViewCount = 0;
  InterstitialAd? _interstitialAd;

  static const String bannerAdUnitId = 'ca-app-pub-5520164831450548/1436339048';
  static const String _interstitialAdUnitId = 'ca-app-pub-5520164831450548/7761230358';

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    // COPPA準拠: 子ども関連アプリのため非パーソナライズ広告のみ配信
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        maxAdContentRating: MaxAdContentRating.g,
      ),
    );
    _loadInterstitialAd();
  }

  BannerAd createBannerAd({AdSize size = AdSize.banner, VoidCallback? onLoaded}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded?.call(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  /// 記録完了時に呼び出す。2回に1回インタースティシャル広告を表示
  void onRecordComplete() {
    _recordCount++;
    if (_recordCount % 2 == 0 && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  /// 詳細画面表示時。5回に1回インタースティシャル広告を表示
  void onDetailView() {
    _detailViewCount++;
    if (_detailViewCount % 5 == 0 && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }
}
