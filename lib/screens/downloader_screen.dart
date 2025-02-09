import 'package:flutter/material.dart';
import 'package:tikup/models/video_model.dart';
import 'package:tikup/services/api_service.dart';
import 'package:tikup/services/download_service.dart';
import 'package:tikup/widgets/video_player_widget.dart';
import 'package:tikup/widgets/download_button.dart';

class DownloaderScreen extends StatefulWidget {
  const DownloaderScreen({super.key});

  @override
  State<DownloaderScreen> createState() => _DownloaderScreenState();
}

class _DownloaderScreenState extends State<DownloaderScreen> {
  final _urlController = TextEditingController();
  bool isLoading = false;
  bool isDownloading = false;
  double downloadProgress = 0;
  VideoModel? videoInfo;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _fetchVideo() async {
    if (_urlController.text.isEmpty) {
      _showError('Please enter a TikTok URL');
      return;
    }

    setState(() {
      isLoading = true;
      videoInfo = null;
    });

    try {
      final info = await ApiService.getVideoInfo(_urlController.text);
      setState(() {
        videoInfo = info;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        isLoading = false;
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
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'Paste TikTok video URL here',
                suffixIcon: IconButton(
                  icon: Icon(Icons.paste),
                  onPressed: () async {
                    // TODO: Implement paste from clipboard
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _fetchVideo,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Find'),
                  SizedBox(width: 8),
                  isLoading
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
              Text(
                videoInfo!.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 8),
              Text(
                'By ${videoInfo!.authorName} • ${videoInfo!.likeCount} likes',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: DownloadButton(
                      onPressed: _downloadVideo,
                      isDownloading: isDownloading,
                      progress: downloadProgress,
                      icon: Icons.video_library,
                      label: 'Save Video',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DownloadButton(
                      onPressed: _downloadAudio,
                      isDownloading: isDownloading,
                      progress: downloadProgress,
                      icon: Icons.music_note,
                      label: 'Save Audio',
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