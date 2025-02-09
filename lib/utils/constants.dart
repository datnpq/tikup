class AppConstants {
  // API Constants
  static const String apiBaseUrl = 'https://tiktok-full-info-without-watermark.p.rapidapi.com';
  static const String apiHost = 'tiktok-full-info-without-watermark.p.rapidapi.com';
  static const String apiKey = 'ca6181bda3msh7d3414d442373d2p1d915bjsnd909d7fb935b';
  static const String apiEndpoint = '/vid/index';
  
  // File Names
  static const String videoFileName = 'tikup_video.mp4';
  static const String audioFileName = 'tikup_audio.mp3';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 30.0;
  static const int splashDuration = 3;
  
  // Colors
  static const int primaryColorValue = 0xFF00F2EA;
  static const int backgroundColorValue = 0xFF121212;
  static const int surfaceColorValue = 0xFF1E1E1E;
  static const int inputColorValue = 0xFF2A2A2A;
  
  // Error Messages
  static const String errorPermissionDenied = 'Permission denied';
  static const String errorInvalidUrl = 'Please enter a valid TikTok URL';
  static const String errorDownloadFailed = 'Failed to download file';
  static const String errorApiFailed = 'Failed to fetch video info';
  static const String errorNoInternet = 'No internet connection';
  
  // Success Messages
  static const String successVideoSaved = 'Video saved to Photos';
  static const String successAudioSaved = 'Audio saved to Files';
} 