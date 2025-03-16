import 'package:flutter/material.dart';
import 'package:tikup/models/video_model.dart';
import 'package:tikup/services/api_service.dart';
import 'package:tikup/services/download_service.dart';
import 'package:tikup/services/history_service.dart';
import 'package:tikup/utils/error_handler.dart';
import 'package:tikup/utils/notification_manager.dart';
import 'package:tikup/widgets/video_player_widget.dart';
import 'package:tikup/widgets/download_button.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tikup/services/ad_service.dart';
import 'package:tikup/widgets/rewarded_ad_dialog.dart';
import 'package:tikup/screens/batch_download_screen.dart';
import 'package:tikup/widgets/premium_purchase_dialog.dart';

class DownloaderScreen extends StatefulWidget {
  @override
  State<DownloaderScreen> createState() => _DownloaderScreenState();
}

class _DownloaderScreenState extends State<DownloaderScreen> {
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;
  bool _showDownloadOptions = false;
  bool _isDownloading = false;
  VideoModel? videoInfo;
  String? _errorMessage;
  final AdService _adService = AdService();
  int _downloadCount = 0;
  bool _isAdFree = false;
  DateTime? _adFreeExpiryTime;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
    _adService.loadInterstitialAd();
    _adService.loadRewardedAd();
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _checkClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        final String clipboardText = data.text!.trim();
        
        // Automatically fill the textfield if it contains a TikTok URL
        if (_isTikTokUrl(clipboardText)) {
          setState(() {
            _linkController.text = clipboardText;
          });
        }
      }
    } catch (e) {
      // Silently handle clipboard errors
      print('Clipboard error: $e');
    }
  }

  bool _isTikTokUrl(String url) {
    return url.contains('tiktok.com/') || 
           url.contains('douyin.com/') ||
           url.contains('vm.tiktok.com/');
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        final String clipboardText = data.text!.trim();
        
        if (_isTikTokUrl(clipboardText)) {
          setState(() {
            _linkController.text = clipboardText;
            _showDownloadOptions = false;
            _errorMessage = null;
          });
          
          // Automatically find the video
          await _findVideo();
        } else {
          _showError('Invalid TikTok link');
        }
      } else {
        _showError('No link in clipboard');
      }
    } catch (e) {
      _showError('Error accessing clipboard: $e');
    }
  }

  Future<void> _findVideo() async {
    if (_linkController.text.isEmpty) {
      _showError('Please enter a TikTok URL');
      return;
    }

    setState(() {
      _isLoading = true;
      videoInfo = null;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final info = await apiService.getVideoInfo(_linkController.text);
      setState(() {
        videoInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorHandler.getReadableErrorMessage(e);
      });
    }
  }

  // Offer temporary ad-free experience via rewarded ad
  void _offerAdFreeExperience() {
    showDialog(
      context: context,
      builder: (context) => RewardedAdDialog(
        title: 'Ad-Free Experience',
        description: 'Watch a short ad now to enjoy 30 minutes of ad-free downloads!',
        buttonText: 'Get Ad-Free Time',
        onRewardEarned: () {
          // Grant 30 minutes of ad-free experience
          setState(() {
            _isAdFree = true;
            _adFreeExpiryTime = DateTime.now().add(Duration(minutes: 30));
          });
          
          NotificationManager.showSuccess(
            context, 
            'You now have 30 minutes of ad-free downloads!'
          );
          
          // Schedule a timer to check when ad-free period expires
          _scheduleAdFreeCheck();
        },
      ),
    );
  }
  
  void _scheduleAdFreeCheck() {
    // Check every minute if the ad-free period has expired
    Future.delayed(Duration(minutes: 1), () {
      if (!mounted) return;
      
      final now = DateTime.now();
      if (_adFreeExpiryTime != null && now.isAfter(_adFreeExpiryTime!)) {
        setState(() {
          _isAdFree = false;
          _adFreeExpiryTime = null;
        });
        
        // Show a notification that ad-free period has ended
        NotificationManager.showInfo(
          context, 
          'Your ad-free period has ended.'
        );
      } else if (_isAdFree) {
        // Continue checking if still in ad-free period
        _scheduleAdFreeCheck();
      }
    });
  }
  
  String get _getAdFreeTimeRemaining {
    if (_adFreeExpiryTime == null) return '';
    
    final now = DateTime.now();
    final remaining = _adFreeExpiryTime!.difference(now);
    
    if (remaining.isNegative) return 'Expired';
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _downloadVideo() async {
    if (videoInfo == null) return;
    
    setState(() {
      _isDownloading = true;
    });
    
    try {
      await DownloadService().downloadVideo(
        videoInfo!,
        (progress) {
          // We're intentionally not showing progress notifications
          // Just update state when download is complete
          if (progress > 0.95) {
            setState(() {
              _isDownloading = false;
              _downloadCount++; // Increment download counter
            });
          }
        }
      );
      
      // Add to history
      await HistoryService().addToHistory(videoInfo!);
      
      // Show success notification
      NotificationManager.showSuccess(context, 'Video saved successfully!');
      
      // Show interstitial ad after every second download, but only if not in ad-free period
      if (!_isAdFree && _downloadCount % 2 == 0) {
        _showInterstitialAd();
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      
      NotificationManager.showError(
        context, 
        'Failed to save video: ${ErrorHandler.getMessage(e)}',
        onRetry: _downloadVideo
      );
      
      ErrorHandler.logError('Download failed', e);
    }
  }

  // Method to display interstitial ad
  Future<void> _showInterstitialAd() async {
    if (_adService.isInterstitialAdReady) {
      await _adService.showInterstitialAd();
    } else {
      // Load for next time
      _adService.loadInterstitialAd();
    }
  }

  Future<void> _toggleBookmark() async {
    if (videoInfo == null) return;
    
    final historyService = HistoryService();
    final updatedVideo = await historyService.toggleBookmark(videoInfo!);
    setState(() {
      videoInfo = updatedVideo;
    });
    
    NotificationManager.showInfo(
      context, 
      updatedVideo.isBookmarked ? 'Added to bookmarks' : 'Removed from bookmarks'
    );
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearError() {
    setState(() {
      _errorMessage = null;
    });
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Show premium purchase dialog
  void _showPremiumPurchaseDialog() {
    showDialog(
      context: context,
      builder: (context) => PremiumPurchaseDialog(),
    ).then((purchased) {
      if (purchased == true) {
        setState(() {
          // Refresh UI to reflect premium status
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and app name with ad-free indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bookmark,
                          color: Colors.cyan,
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'TikUP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    
                    Row(
                      children: [
                        // Batch download button
                        IconButton(
                          icon: Icon(
                            Icons.format_list_bulleted,
                            color: Colors.cyan,
                            size: 28,
                          ),
                          tooltip: 'Batch Download',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BatchDownloadScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 8),
                        
                        // Ad-free status indicator or get ad-free button
                        if (_adService.isPremium)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.purple.shade300, Colors.purple.shade700],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                                SizedBox(width: 5),
                                Text(
                                  'Premium',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          TextButton.icon(
                            onPressed: _showPremiumPurchaseDialog,
                            icon: Icon(Icons.workspace_premium, size: 16),
                            label: Text('Go Premium'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.purple,
                              backgroundColor: Colors.purple.withOpacity(0.1),
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 32),
                
                // Search box with enhanced styling
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _linkController,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Paste TikTok link here...',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.link,
                              color: Colors.cyan.withOpacity(0.7),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            suffixIcon: _linkController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        _linkController.clear();
                                        videoInfo = null;
                                        _errorMessage = null;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) => setState(() {}),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _findVideo();
                            }
                          },
                        ),
                      ),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.cyan,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(25),
                          ),
                          gradient: LinearGradient(
                            colors: [Colors.cyan.shade300, Colors.cyan.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.content_paste_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _isLoading ? null : _pasteFromClipboard,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Find button with enhanced design
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _linkController.text.isEmpty || _isLoading
                        ? null
                        : _findVideo,
                    icon: _isLoading 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.search, size: 20),
                    label: Text(
                      _isLoading ? 'Searching...' : 'Find Video',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      disabledBackgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                      shadowColor: Colors.cyan.withOpacity(0.4),
                    ),
                  ),
                ),
                
                // Error message with improved styling
                if (_errorMessage != null) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[300],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red[300], size: 16),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: _clearError,
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Video information and player with enhanced styling
                if (videoInfo != null) ...[
                  SizedBox(height: 24),
                  
                  // Video player with shadow and border
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withOpacity(0.2),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: VideoPlayerWidget(url: videoInfo!.videoUrl),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Description with enhanced styling
                  if (videoInfo!.description.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              videoInfo!.description,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(
                                  videoInfo!.isBookmarked
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: videoInfo!.isBookmarked
                                      ? Colors.cyan
                                      : Colors.grey[400],
                                  size: 24,
                                ),
                                onPressed: _toggleBookmark,
                                tooltip: videoInfo!.isBookmarked
                                    ? 'Remove from bookmarks'
                                    : 'Add to bookmarks',
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.share,
                                  color: Colors.cyan,
                                  size: 24,
                                ),
                                onPressed: () => _shareVideo(),
                                tooltip: 'Share video link',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 24),
                  
                  // Download button with enhanced styling
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isDownloading
                            ? [Colors.grey.shade600, Colors.grey.shade800]
                            : [Colors.cyan.shade300, Colors.cyan.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: _isDownloading
                              ? Colors.black.withOpacity(0.2)
                              : Colors.cyan.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: !_isDownloading ? _downloadVideo : null,
                      icon: _isDownloading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2.0,
                              ),
                            )
                          : Icon(Icons.download, size: 24),
                      label: Text(
                        _isDownloading ? 'Saving Video...' : 'Save Video',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        disabledForegroundColor: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // No Logo download button
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: !_isDownloading ? () {
                        // Implement no logo download
                        _showInfo('This feature will be available soon!');
                      } : null,
                      icon: Icon(Icons.logo_dev_outlined),
                      label: Text(
                        'Save Without Watermark',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.transparent,
                        disabledForegroundColor: Colors.white.withOpacity(0.5),
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
                
                // Empty state when no URL entered - Enhanced version
                if (videoInfo == null && !_isLoading && _errorMessage == null) ...[
                  SizedBox(height: 60),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyan.withOpacity(0.15),
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.download_rounded,
                            size: 60,
                            color: Colors.cyan,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Download TikTok Videos Easily',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            '1. Copy video link from TikTok\n2. Paste it in the field above\n3. Download your video in high quality',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 30),
                        OutlinedButton.icon(
                          onPressed: _pasteFromClipboard,
                          icon: Icon(Icons.content_paste),
                          label: Text('Paste from Clipboard'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.cyan,
                            side: BorderSide(color: Colors.cyan.withOpacity(0.5)),
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Add this method to share the video link
  Future<void> _shareVideo() async {
    if (videoInfo == null) return;
    
    try {
      final String shareText = 'Check out this TikTok video I found using TikUP!\n\n'
          '${_linkController.text}\n\n'
          'Download TikUP to get videos without watermark.';
      
      await Share.share(shareText, subject: 'TikTok Video from TikUP');
    } catch (e) {
      _showError('Failed to share: ${e.toString()}');
    }
  }
} 