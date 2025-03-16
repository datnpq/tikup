class DownloadItem {
  final String url;
  final String? title;
  final String? thumbnailUrl;
  bool isDownloading;
  double progress;
  bool isCompleted;
  String? error;
  
  DownloadItem({
    required this.url,
    this.title,
    this.thumbnailUrl,
    this.isDownloading = false,
    this.progress = 0.0,
    this.isCompleted = false,
    this.error,
  });
} 