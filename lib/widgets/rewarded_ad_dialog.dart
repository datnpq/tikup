import 'package:flutter/material.dart';
import 'package:tikup/services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdDialog extends StatefulWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onRewardEarned;
  
  const RewardedAdDialog({
    Key? key,
    required this.title,
    required this.description,
    this.buttonText = 'Watch Ad',
    required this.onRewardEarned,
  }) : super(key: key);

  @override
  State<RewardedAdDialog> createState() => _RewardedAdDialogState();
}

class _RewardedAdDialogState extends State<RewardedAdDialog> {
  final AdService _adService = AdService();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    if (!_adService.isRewardedAdReady) {
      setState(() => _isLoading = true);
      _adService.loadRewardedAd();
      
      // Poll for ad readiness
      _checkAdReadiness();
    }
  }
  
  Future<void> _checkAdReadiness() async {
    // Check if ad is ready every second for up to 5 seconds
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (_adService.isRewardedAdReady) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
    }
    
    // Still not ready after 5 seconds
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _showRewardedAd() async {
    if (!_adService.isRewardedAdReady) {
      setState(() => _isLoading = true);
      _adService.loadRewardedAd();
      
      // Show message that ad is loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ad is preparing, please try again in a moment.'),
          duration: Duration(seconds: 2),
        ),
      );
      
      await _checkAdReadiness();
      return;
    }
    
    // Close the dialog
    Navigator.of(context).pop();
    
    // Show the ad
    await _adService.showRewardedAd(
      onUserEarnedReward: (ad, reward) {
        // Call the reward callback
        widget.onRewardEarned();
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.description),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.cyan.shade300, Colors.cyan.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _showRewardedAd,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _isLoading 
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Loading Ad...'),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_outline),
                        SizedBox(width: 8),
                        Text(widget.buttonText),
                      ],
                    ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('No Thanks'),
        ),
      ],
    );
  }
} 