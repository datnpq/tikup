import 'package:flutter/material.dart';
import 'package:tikup/models/video_model.dart';
import 'package:tikup/screens/video_detail_screen.dart';
import 'package:tikup/services/download_service.dart';
import 'package:tikup/utils/constants.dart';
import 'package:tikup/utils/helpers.dart';
import 'package:tikup/utils/error_handler.dart';
import 'package:tikup/utils/notification_manager.dart';
import 'package:share_plus/share_plus.dart';

class VideoListItem extends StatefulWidget {
  final VideoModel video;
  final Function(VideoModel) onToggleBookmark;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const VideoListItem({
    Key? key,
    required this.video,
    required this.onToggleBookmark,
    this.onDelete,
    this.onTap,
  }) : super(key: key);

  @override
  State<VideoListItem> createState() => _VideoListItemState();
}

class _VideoListItemState extends State<VideoListItem> with SingleTickerProviderStateMixin {
  bool _isDownloading = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: widget.onTap ?? () => _navigateToDetail(context),
          onTapDown: (_) => _animController.forward(),
          onTapUp: (_) => _animController.reverse(),
          onTapCancel: () => _animController.reverse(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced Thumbnail with Hero animation
                    Hero(
                      tag: 'thumbnail-${widget.video.id}',
                      child: Container(
                        width: 110,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                          image: widget.video.thumbnailUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(widget.video.thumbnailUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: Stack(
                          children: [
                            // Play icon overlay on thumbnail
                            if (widget.video.thumbnailUrl.isEmpty)
                              Center(
                                child: Icon(
                                  Icons.play_circle_outline,
                                  size: 40,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
                    
                    // Text content with enhanced styling
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Description with better styling
                          Text(
                            widget.video.description.isNotEmpty 
                                ? widget.video.description 
                                : 'TikTok Video',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 6),
                          
                          // Author if available
                          if (widget.video.authorName.isNotEmpty) 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.cyan,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.video.authorName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Date with enhanced styling
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              Helpers.formatDateTime(widget.video.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 14),
                          
                          // Action buttons with better layout
                          Container(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Re-download button
                                _buildActionButton(
                                  icon: _isDownloading 
                                      ? Icons.hourglass_empty 
                                      : Icons.download,
                                  color: Colors.cyan[700],
                                  tooltip: 'Download again',
                                  onPressed: _isDownloading 
                                      ? null 
                                      : () => _redownloadVideo(context),
                                ),
                                
                                // Share button
                                _buildActionButton(
                                  icon: Icons.share,
                                  color: Colors.blue[700],
                                  tooltip: 'Share',
                                  onPressed: () => _shareVideo(context),
                                ),
                                
                                // Bookmark button with animation
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    color: widget.video.isBookmarked 
                                        ? Colors.amber.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: _buildActionButton(
                                    icon: widget.video.isBookmarked 
                                        ? Icons.bookmark 
                                        : Icons.bookmark_border,
                                    color: widget.video.isBookmarked 
                                        ? Colors.amber[700]
                                        : Colors.grey[700],
                                    tooltip: widget.video.isBookmarked 
                                        ? 'Remove from bookmarks' 
                                        : 'Add to bookmarks',
                                    onPressed: () => widget.onToggleBookmark(widget.video),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    Color? color,
    VoidCallback? onPressed,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 1),
      child: IconButton(
        icon: Icon(icon, size: 20),
        padding: EdgeInsets.all(6),
        constraints: BoxConstraints(),
        color: color,
        tooltip: tooltip,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove from History'),
        content: Text('Are you sure you want to remove this video from your history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Remove'),
          ),
        ],
      ),
    );
    
    if (result == true && widget.onDelete != null) {
      widget.onDelete!();
    }
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoDetailScreen(video: widget.video),
      ),
    );
  }

  Future<void> _redownloadVideo(BuildContext context) async {
    if (_isDownloading) return;
    
    setState(() {
      _isDownloading = true;
    });
    
    try {
      NotificationManager.showInfo(
        context, 
        'Saving video...',
      );

      final downloadService = DownloadService();
      await downloadService.downloadVideo(
        widget.video,
        (progress) {
          // Only update state when download completes
          if (progress > 0.95) {
            setState(() {
              _isDownloading = false;
            });
          }
        },
      );

      NotificationManager.showSuccess(
        context, 
        'Video saved successfully!',
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      
      final message = ErrorHandler.getReadableErrorMessage(e);
      NotificationManager.showError(
        context,
        'Failed to save video: $message',
        onRetry: () => _redownloadVideo(context),
      );
      
      ErrorHandler.logError('Video download failed', e);
    }
  }
  
  Future<void> _shareVideo(BuildContext context) async {
    try {
      final String shareText = 'Check out this TikTok video I found using TikUP!\n\n'
          '${widget.video.description}\n\n'
          'Download TikUP to save your favorite videos.';
      
      await Share.share(shareText, subject: 'TikTok Video from TikUP');
    } catch (e) {
      NotificationManager.showError(
        context,
        'Failed to share: ${e.toString()}',
      );
    }
  }
} 