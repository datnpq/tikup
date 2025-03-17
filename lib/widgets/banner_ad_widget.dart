import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tikup/services/ad_service.dart';
import 'package:tikup/utils/ad_helper.dart';

class BannerAdWidget extends StatefulWidget {
  final double maxHeight;
  final Color backgroundColor;
  
  const BannerAdWidget({
    Key? key,
    this.maxHeight = 90,
    this.backgroundColor = Colors.black,
  }) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  final AdService _adService = AdService();
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = true;
  int _retryAttempt = 0;
  static const int _maxRetries = 3;
  
  @override
  void initState() {
    super.initState();
    _loadAd();
  }
  
  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
  
  void _loadAd() {
    // Don't load ads for premium users
    if (_adService.isPremium) return;
    
    setState(() {
      _isAdLoading = true;
    });
    
    _loadBannerWithSize(AdSize.banner);
  }
  
  void _loadBannerWithSize(AdSize adSize) {
    if (_bannerAd != null) {
      _bannerAd!.dispose();
      _bannerAd = null;
    }
    
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded successfully with size: ${adSize.width}x${adSize.height}');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _isAdLoading = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}');
          debugPrint('Banner ad error code: ${error.code}');
          ad.dispose();
          _bannerAd = null;
          
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _isAdLoading = false;
            });
          }
          
          // If banner ad fails, try with a different size
          if (adSize == AdSize.banner && _retryAttempt < _maxRetries) {
            _retryAttempt++;
            debugPrint('Trying with medium rectangle size instead');
            _loadBannerWithSize(AdSize.mediumRectangle);
          } else if (adSize == AdSize.mediumRectangle && _retryAttempt < _maxRetries) {
            _retryAttempt++;
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
  
  @override
  Widget build(BuildContext context) {
    // If user is premium or no ad is loaded, return a minimal container
    if (_adService.isPremium || (!_isAdLoaded && !_isAdLoading) || _bannerAd == null) {
      return Container(
        width: double.infinity,
        height: 0, // No height when no ad is loaded or user is premium
      );
    }
    
    // Show loading indicator while ad is loading
    if (_isAdLoading) {
      return Container(
        width: double.infinity,
        height: 50,
        color: widget.backgroundColor,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
        ),
      );
    }
    
    // Get the ad's width and height
    final double adWidth = _bannerAd!.size.width.toDouble();
    final double adHeight = _bannerAd!.size.height.toDouble();
    
    // Calculate the height - capped at maxHeight
    final double height = adHeight > widget.maxHeight ? widget.maxHeight : adHeight;
    
    return Container(
      width: double.infinity, // Full width container
      height: height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey[900]!,
            width: 0.5,
          ),
        ),
      ),
      // Center the ad in case it doesn't take full width
      child: Center(
        child: Container(
          width: adWidth,
          height: adHeight,
          alignment: Alignment.center,
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
} 