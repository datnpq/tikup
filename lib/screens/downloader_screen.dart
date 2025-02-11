import 'package:flutter/material.dart';
import 'package:tikup/models/video_model.dart';
import 'package:tikup/services/api_service.dart';
import 'package:tikup/services/download_service.dart';
import 'package:tikup/widgets/video_player_widget.dart';
import 'package:tikup/widgets/download_button.dart';
import 'package:flutter/services.dart';

class DownloaderScreen extends StatefulWidget {
  const DownloaderScreen({super.key});

  @override
  State<DownloaderScreen> createState() => _DownloaderScreenState();
}

class _DownloaderScreenState extends State<DownloaderScreen> {
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;
  bool _showDownloadOptions = false;
  String? _thumbnailUrl;
  String? _videoTitle;
  bool isDownloading = false;
  double downloadProgress = 0;
  VideoModel? videoInfo;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        final String clipboardText = data.text!.trim();
        
        // Kiểm tra nếu là link TikTok hợp lệ
        if (clipboardText.contains('tiktok.com/') || 
            clipboardText.contains('douyin.com/') ||
            clipboardText.contains('vm.tiktok.com/')) {
          
          setState(() {
            _linkController.text = clipboardText;
            _showDownloadOptions = false; // Reset download options khi paste link mới
          });
          
          // Tự động tìm kiếm sau khi paste
          await _findVideo();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid TikTok link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No link in clipboard'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing clipboard: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    });

    try {
      final info = await ApiService.getVideoInfo(_linkController.text);
      setState(() {
        videoInfo = info;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadVideo() async {
    if (videoInfo == null) return;

    try {
      await DownloadService.downloadVideo(
        videoInfo!.downloadUrl,
        'tikup_video.mp4',
        (progress) {
          setState(() {
            downloadProgress = progress;
          });
        },
      );
      _showSuccess('Video saved to Photos');
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _downloadAudio() async {
    if (videoInfo == null) return;

    try {
      await DownloadService.downloadAudio(
        videoInfo!.musicUrl,
        'tikup_audio.mp3',
        (progress) {
          setState(() {
            downloadProgress = progress;
          });
        },
      );
      _showSuccess('Audio saved to Files');
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border),
            SizedBox(width: 8),
            Text('TikUP'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _linkController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Paste TikTok link here...',
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  if (_linkController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _linkController.clear();
                        setState(() {
                          _showDownloadOptions = false;
                        });
                      },
                    ),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(25)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.content_paste, color: Colors.black),
                      onPressed: _isLoading ? null : _pasteFromClipboard,
                      tooltip: 'Paste from clipboard',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _findVideo,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Find'),
                  SizedBox(width: 8),
                  _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Icon(Icons.search, size: 20),
                ],
              ),
            ),
            if (videoInfo != null) ...[
              SizedBox(height: 24),
              VideoPlayerWidget(url: videoInfo!.videoUrl),
              SizedBox(height: 16),
              // Text(
              //   videoInfo!.description,
              //   style: Theme.of(context).textTheme.bodyLarge,
              // ),
              // SizedBox(height: 8),
              // Text(
              //   'By ${videoInfo!.authorName} • ${videoInfo!.likeCount} likes',
              //   style: Theme.of(context).textTheme.bodyMedium,
              // ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: DownloadButton(
                      onPressed: _downloadVideo,
                      isDownloading: isDownloading,
                      progress: downloadProgress,
                      icon: Icons.video_library,
                      label: 'Video',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DownloadButton(
                      onPressed: _downloadAudio,
                      isDownloading: isDownloading,
                      progress: downloadProgress,
                      icon: Icons.music_note,
                      label: 'Audio',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
} 