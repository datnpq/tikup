import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tikup/models/video_model.dart';
import 'package:tikup/services/download_service.dart';
import 'package:tikup/services/history_service.dart';
import 'package:tikup/utils/error_handler.dart';
import 'package:tikup/utils/helpers.dart';
import 'package:tikup/utils/notification_manager.dart';
import 'package:tikup/widgets/video_player_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:tikup/services/ad_service.dart';
import 'package:tikup/widgets/rewarded_ad_dialog.dart';

class VideoDetailScreen extends StatefulWidget {
  final VideoModel video;

  const VideoDetailScreen({Key? key, required this.video}) : super(key: key);

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> with SingleTickerProviderStateMixin {
  bool _isDownloading = false;
  String? _errorMessage;
  late VideoModel _video;
  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;
  final AdService _adService = AdService();
  int _downloadCount = 0;
  
  @override
  void initState() {
    super.initState();
    _video = widget.video;
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Create button scale animation
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Ensure an interstitial ad is loaded
    _adService.loadInterstitialAd();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareVideo,
            tooltip: 'Share video',
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: _video.isBookmarked ? Colors.cyan.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(
                _video.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _video.isBookmarked ? Colors.cyan : Colors.white,
              ),
              onPressed: _toggleBookmark,
              tooltip: _video.isBookmarked 
                  ? 'Remove from bookmarks' 
                  : 'Add to bookmarks',
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video player with enhanced styling
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.2),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: VideoPlayerWidget(
              url: _video.videoUrl,
              aspectRatio: 9 / 16, // TikTok style aspect ratio
              autoPlay: true,
            ),
          ),
          
          // Error message if any
          if (_errorMessage != null)
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
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
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          
          // Video info with enhanced styling
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _video.description,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          if (_video.authorName.isNotEmpty) ...[
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.person, size: 16, color: Colors.cyan),
                                SizedBox(width: 8),
                                Text(
                                  'By ${_video.authorName}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Download date
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: 16, color: Colors.grey[400]),
                          SizedBox(width: 8),
                          Text(
                            'Downloaded ${Helpers.formatDateTime(_video.timestamp)}',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Download buttons with animations
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTapDown: (_) {
                              if (!_isDownloading) _animationController.forward();
                            },
                            onTapUp: (_) {
                              _animationController.reverse();
                              if (!_isDownloading) _downloadVideo();
                            },
                            onTapCancel: () {
                              _animationController.reverse();
                            },
                            child: ScaleTransition(
                              scale: _buttonScaleAnimation,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.cyan.shade300, Colors.cyan.shade700],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isDownloading 
                                          ? Colors.transparent 
                                          : Colors.cyan.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isDownloading
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Saving...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.download, color: Colors.white, size: 24),
                                            SizedBox(width: 12),
                                            Text(
                                              'Save Video',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // No Logo Button
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: !_isDownloading ? _downloadVideoNoLogo : null,
                                child: Center(
                                  child: _isDownloading
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Please Wait...',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.7),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.logo_dev_outlined, color: Colors.white, size: 22),
                                            SizedBox(width: 12),
                                            Text(
                                              'Save Video (No Logo)',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add helper method to show a permission dialog
  Future<bool> _showPermissionDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _downloadVideo() async {
    if (_isDownloading) return;
    
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });
    
    try {
      // Request permission exactly when the save button is clicked
      if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            // Show dialog with option to open settings
            bool shouldOpenSettings = await _showPermissionDialog(
              'Photo Library Access Required',
              'TikUp needs access to your photo library to save videos. Please enable this in Settings.'
            );
            
            if (shouldOpenSettings) {
              await openAppSettings();
            }
            throw Exception('Photo library access denied. Please enable in Settings and try again.');
          } else if (status.isDenied) {
            throw Exception('Permission denied to access photo library. Please grant permission to save videos.');
          }
        }
      } else if (Platform.isAndroid) {
        // For Android
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            // Show dialog with option to open settings
            bool shouldOpenSettings = await _showPermissionDialog(
              'Storage Permission Required',
              'TikUp needs storage permission to save videos. Please enable this in Settings.'
            );
            
            if (shouldOpenSettings) {
              await openAppSettings();
            }
            throw Exception('Storage permission denied. Please enable in Settings and try again.');
          } else if (status.isDenied) {
            throw Exception('Permission denied to access storage. Please grant permission to save videos.');
          }
        }
      }
      
      // Use a simpler progress callback that doesn't trigger UI updates frequently
      await DownloadService().downloadVideo(
        _video,
        (progress) {
          // Only update state at 25%, 50%, 75% and 100% to reduce rebuilds
          if (progress > 0.99) {
            setState(() {
              _isDownloading = false;
              _downloadCount++;
            });
          }
        },
      );
      
      NotificationManager.showSuccess(context, 'Video saved successfully!');
      
      // Show an interstitial ad every second successful download
      if (_downloadCount % 2 == 0) {
        _showInterstitialAd();
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      
      String errorMessage = ErrorHandler.getMessage(e);
      NotificationManager.showError(
        context, 
        'Failed to save video: $errorMessage',
        onRetry: () {
          if (errorMessage.contains('Permission')) {
            // If it's a permission error, open settings
            openAppSettings();
          } else {
            _downloadVideo();
          }
        }
      );
      
      ErrorHandler.logError('Video download failed', e);
    }
  }

  Future<void> _downloadVideoNoLogo() async {
    if (_isDownloading) return;
    
    // Show rewarded ad dialog as this is a premium feature
    showDialog(
      context: context,
      builder: (context) => RewardedAdDialog(
        title: 'Premium Feature',
        description: 'Watch a short ad to unlock watermark-free download.',
        buttonText: 'Watch Ad to Unlock',
        onRewardEarned: () {
          // After the ad is watched and reward is earned, start the download
          _performNoLogoDownload();
        },
      ),
    );
  }
  
  // This method handles the actual download logic after the reward is earned
  Future<void> _performNoLogoDownload() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });
    
    try {
      // Request permission exactly when the save button is clicked
      if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            // Show dialog with option to open settings
            bool shouldOpenSettings = await _showPermissionDialog(
              'Photo Library Access Required',
              'TikUp needs access to your photo library to save videos. Please enable this in Settings.'
            );
            
            if (shouldOpenSettings) {
              await openAppSettings();
            }
            throw Exception('Photo library access denied. Please enable in Settings and try again.');
          } else if (status.isDenied) {
            throw Exception('Permission denied to access photo library. Please grant permission to save videos.');
          }
        }
      } else if (Platform.isAndroid) {
        // For Android
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            // Show dialog with option to open settings
            bool shouldOpenSettings = await _showPermissionDialog(
              'Storage Permission Required',
              'TikUp needs storage permission to save videos. Please enable this in Settings.'
            );
            
            if (shouldOpenSettings) {
              await openAppSettings();
            }
            throw Exception('Storage permission denied. Please enable in Settings and try again.');
          } else if (status.isDenied) {
            throw Exception('Permission denied to access storage. Please grant permission to save videos.');
          }
        }
      }
      
      // Use a simpler progress callback that doesn't trigger UI updates frequently
      await DownloadService().downloadVideoNoLogo(
        _video,
        (progress) {
          // Only update state at 25%, 50%, 75% and 100% to reduce rebuilds
          if (progress > 0.99) {
            setState(() {
              _isDownloading = false;
              _downloadCount++;
            });
          }
        },
      );
      
      NotificationManager.showSuccess(context, 'Video saved successfully without watermark!');
      
      // We don't show another ad after download since they already watched one to unlock this feature
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      
      String errorMessage = ErrorHandler.getMessage(e);
      NotificationManager.showError(
        context, 
        'Failed to save video: $errorMessage',
        onRetry: () {
          if (errorMessage.contains('Permission')) {
            // If it's a permission error, open settings
            openAppSettings();
          } else {
            _downloadVideoNoLogo();
          }
        }
      );
      
      ErrorHandler.logError('Video download failed', e);
    }
  }
  
  // Show an interstitial ad
  Future<void> _showInterstitialAd() async {
    if (_adService.isInterstitialAdReady) {
      await _adService.showInterstitialAd();
    } else {
      // If not ready, preload for next time
      _adService.loadInterstitialAd();
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      bool newState = !_video.isBookmarked;
      
      // Update the video model
      setState(() {
        _video = _video.copyWith(isBookmarked: newState);
      });
      
      // Update in history service
      await HistoryService().updateVideoBookmarkStatus(_video.id, newState);
      
      NotificationManager.showInfo(
        context, 
        newState ? 'Added to bookmarks' : 'Removed from bookmarks'
      );
    } catch (e) {
      // Revert the state if there was an error
      setState(() {
        _video = _video.copyWith(isBookmarked: !_video.isBookmarked);
      });
      
      NotificationManager.showError(
        context, 
        'Failed to update bookmark: ${ErrorHandler.getMessage(e)}'
      );
      
      ErrorHandler.logError('Bookmark toggle failed', e);
    }
  }

  void _shareVideo() {
    try {
      Share.share(
        'Check out this TikTok video: ${_video.originalUrl ?? ""}',
        subject: 'TikTok Video'
      );
    } catch (e) {
      NotificationManager.showError(context, 'Failed to share video');
      ErrorHandler.logError('Share failed', e);
    }
  }
} 