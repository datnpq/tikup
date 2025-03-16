import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  // Use test ads in debug mode, real ads in release mode
  static final bool _useTestAds = kDebugMode;
  
  // Banner Ad Unit IDs
  static String get bannerAdUnitId {
    if (_useTestAds) {
      // Test ad unit IDs
      return 'ca-app-pub-3940256099942544/6300978111'; // Test banner ad unit ID
    } else if (Platform.isAndroid) {
      // Android banner ad unit ID
      return 'ca-app-pub-3566207539697923/7863545127'; // Production banner ad unit ID
    } else if (Platform.isIOS) {
      // iOS banner ad unit ID
      return 'ca-app-pub-3566207539697923/1117672367'; // Production banner ad unit ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  // Interstitial Ad Unit IDs
  static String get interstitialAdUnitId {
    if (_useTestAds) {
      // Test ad unit IDs
      return 'ca-app-pub-3940256099942544/1033173712'; // Test interstitial ad unit ID
    } else if (Platform.isAndroid) {
      // Android interstitial ad unit ID
      return 'ca-app-pub-3566207539697923/1033173712'; // Production Android interstitial ad unit ID
    } else if (Platform.isIOS) {
      // iOS interstitial ad unit ID
      return 'ca-app-pub-3566207539697923/4411468910'; // Production iOS interstitial ad unit ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  // Rewarded Ad Unit IDs
  static String get rewardedAdUnitId {
    if (_useTestAds) {
      // Test ad unit IDs
      return 'ca-app-pub-3940256099942544/5224354917'; // Test rewarded ad unit ID
    } else if (Platform.isAndroid) {
      // Android rewarded ad unit ID
      return 'ca-app-pub-3566207539697923/5224354917'; // Production Android rewarded ad unit ID
    } else if (Platform.isIOS) {
      // iOS rewarded ad unit ID
      return 'ca-app-pub-3566207539697923/1712485313'; // Production iOS rewarded ad unit ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  // App ID
  static String get appId {
    if (_useTestAds) {
      // Test app ID
      return 'ca-app-pub-3940256099942544~1458002511'; // Test app ID
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-3566207539697923~2062755234'; // Production Android app ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3566207539697923~2526956953'; // Production iOS app ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  // Test Device IDs for ad testing
  static List<String> get testDeviceIds {
    return [
      'kGADSimulatorID', // iOS simulator
      '00008110-001879562638801E', // Add your test device IDs here
    ];
  }
} 