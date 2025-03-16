import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tikup/utils/ad_helper.dart';
import 'package:tikup/services/purchase_service.dart';

class AdService {
  // Singleton pattern
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Ad states
  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;
  bool _isBannerAdReady = false;
  
  // Purchase service
  final PurchaseService _purchaseService = PurchaseService();
  
  // Public getters
  bool get isInterstitialAdReady => _isInterstitialAdReady;
  bool get isRewardedAdReady => _isRewardedAdReady;
  bool get isBannerAdReady => _isBannerAdReady && !_purchaseService.isPremium;
  BannerAd? get bannerAd => _purchaseService.isPremium ? null : _bannerAd;
  
  // Premium status getter
  bool get isPremium => _purchaseService.isPremium;
  
  // Public method to get the purchase service
  PurchaseService get purchaseService => _purchaseService;

  /// Initialize the AdMob SDK
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize purchase service first
      await _purchaseService.initialize();
      
      // If user is premium, we don't need to initialize ads
      if (_purchaseService.isPremium) {
        debugPrint('User has premium status, skipping ad initialization');
        _isInitialized = true;
        return;
      }
      
      await MobileAds.instance.initialize();
      
      // Set up MobileAds configuration to use test devices
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: AdHelper.testDeviceIds),
      );
      
      _isInitialized = true;
      
      // Load ads after initialization
      loadInterstitialAd();
      loadRewardedAd();
      loadBannerAd();
      
      debugPrint('AdMob SDK initialized successfully with app ID: ${AdHelper.appId}');
    } catch (e) {
      debugPrint('Error initializing AdMob SDK: $e');
    }
  }

  /// Load a banner ad
  void loadBannerAd() {
    if (!_isInitialized || _purchaseService.isPremium) {
      debugPrint('Skipping banner ad loading: ${!_isInitialized ? 'AdService not initialized' : 'User has premium status'}');
      return;
    }
    
    if (_bannerAd != null) {
      _bannerAd!.dispose();
      _bannerAd = null;
    }
    
    // Try different ad sizes if one fails
    _loadBannerWithSize(AdSize.banner);
  }
  
  /// Load a banner ad with a specific size
  void _loadBannerWithSize(AdSize adSize) {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded successfully with size: ${adSize.width}x${adSize.height}');
          _isBannerAdReady = true;
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}');
          debugPrint('Banner ad error code: ${error.code}');
          debugPrint('Banner ad unit ID: ${AdHelper.bannerAdUnitId}');
          _isBannerAdReady = false;
          ad.dispose();
          _bannerAd = null;
          
          // If banner ad fails, try with a different size
          if (adSize == AdSize.banner) {
            debugPrint('Trying with medium rectangle size instead');
            _loadBannerWithSize(AdSize.mediumRectangle);
          } else if (adSize == AdSize.mediumRectangle) {
            debugPrint('Trying with large banner size instead');
            _loadBannerWithSize(AdSize.largeBanner);
          }
        },
        onAdOpened: (ad) => debugPrint('Banner ad opened'),
        onAdClosed: (ad) => debugPrint('Banner ad closed'),
      ),
    );
    
    _bannerAd!.load();
  }
  
  /// Load an interstitial ad
  void loadInterstitialAd() {
    if (!_isInitialized || _purchaseService.isPremium) {
      debugPrint('Skipping interstitial ad loading: ${!_isInitialized ? 'AdService not initialized' : 'User has premium status'}');
      return;
    }
    
    if (_interstitialAd != null) {
      _interstitialAd!.dispose();
      _interstitialAd = null;
      _isInterstitialAdReady = false;
    }
    
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          debugPrint('Interstitial ad loaded successfully');
          
          // Set callback for ad closing
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Interstitial ad dismissed');
              ad.dispose();
              _isInterstitialAdReady = false;
              // Reload ad for next time
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: ${error.message}');
              ad.dispose();
              _isInterstitialAdReady = false;
              // Reload ad for next time
              loadInterstitialAd();
            },
            onAdShowedFullScreenContent: (ad) {
              debugPrint('Interstitial ad showed full screen content');
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: ${error.message}');
          _isInterstitialAdReady = false;
          // Try loading again after a delay
          Future.delayed(const Duration(minutes: 1), loadInterstitialAd);
        },
      ),
    );
  }
  
  /// Load a rewarded ad
  void loadRewardedAd() {
    if (!_isInitialized) {
      debugPrint('AdService not initialized, skipping rewarded ad loading');
      return;
    }
    
    if (_rewardedAd != null) {
      _rewardedAd!.dispose();
      _rewardedAd = null;
      _isRewardedAdReady = false;
    }
    
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          debugPrint('Rewarded ad loaded successfully');
          
          // Set callback for ad closing
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Rewarded ad dismissed');
              ad.dispose();
              _isRewardedAdReady = false;
              // Reload ad for next time
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Rewarded ad failed to show: ${error.message}');
              ad.dispose();
              _isRewardedAdReady = false;
              // Reload ad for next time
              loadRewardedAd();
            },
            onAdShowedFullScreenContent: (ad) {
              debugPrint('Rewarded ad showed full screen content');
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: ${error.message}');
          _isRewardedAdReady = false;
          // Try loading again after a delay
          Future.delayed(const Duration(minutes: 1), loadRewardedAd);
        },
      ),
    );
  }
  
  /// Show interstitial ad if it's ready
  Future<bool> showInterstitialAd() async {
    // Skip showing ads for premium users
    if (_purchaseService.isPremium) {
      debugPrint('User has premium status, skipping interstitial ad');
      return true; // Return true to continue with the app flow
    }
    
    if (!_isInterstitialAdReady || _interstitialAd == null) {
      debugPrint('Interstitial ad not ready, loading a new one');
      loadInterstitialAd();
      return false;
    }
    
    try {
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
      _isInterstitialAdReady = false;
      loadInterstitialAd();
      return false;
    }
  }
  
  /// Show rewarded ad if it's ready
  /// Returns true if the ad was shown successfully
  Future<bool> showRewardedAd({required Function(AdWithoutView ad, RewardItem reward) onUserEarnedReward}) async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      debugPrint('Rewarded ad not ready, loading a new one');
      loadRewardedAd();
      return false;
    }
    
    try {
      await _rewardedAd!.show(onUserEarnedReward: onUserEarnedReward);
      return true;
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
      _isRewardedAdReady = false;
      loadRewardedAd();
      return false;
    }
  }
  
  /// Dispose of all ads to free up resources
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    
    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
    
    _isBannerAdReady = false;
    _isInterstitialAdReady = false;
    _isRewardedAdReady = false;
  }
} 