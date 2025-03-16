class VideoModel {
  final String id;
  final String videoUrl;
  final String musicUrl;
  final String description;
  final String thumbnailUrl;
  final String authorName;
  final int likeCount;
  final String downloadUrl;
  final String? originalUrl;
  final String? noWatermarkUrl;
  final int timestamp;
  final bool isBookmarked;

  VideoModel({
    String? id,
    required this.videoUrl,
    required this.musicUrl,
    required this.description,
    this.thumbnailUrl = '',
    this.authorName = '',
    this.likeCount = 0,
    required this.downloadUrl,
    this.originalUrl,
    this.noWatermarkUrl,
    int? timestamp,
    this.isBookmarked = false,
  }) : 
    this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    this.timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      videoUrl: json['videoUrl'] ?? json['video']?[0] ?? '',
      musicUrl: json['musicUrl'] ?? json['music']?[0] ?? '',
      description: json['description'] is List ? json['description'][0] : json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      authorName: json['authorName'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      downloadUrl: json['downloadUrl'] ?? json['videoUrl'] ?? json['video']?[0] ?? '',
      originalUrl: json['originalUrl'],
      noWatermarkUrl: json['noWatermarkUrl'],
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      isBookmarked: json['isBookmarked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoUrl': videoUrl,
      'musicUrl': musicUrl,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'authorName': authorName,
      'likeCount': likeCount,
      'downloadUrl': downloadUrl,
      'originalUrl': originalUrl,
      'noWatermarkUrl': noWatermarkUrl,
      'timestamp': timestamp,
      'isBookmarked': isBookmarked,
    };
  }

  VideoModel copyWith({
    String? id,
    String? videoUrl,
    String? musicUrl,
    String? description,
    String? thumbnailUrl,
    String? authorName,
    int? likeCount,
    String? downloadUrl,
    String? originalUrl,
    String? noWatermarkUrl,
    int? timestamp,
    bool? isBookmarked,
  }) {
    return VideoModel(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      musicUrl: musicUrl ?? this.musicUrl,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      authorName: authorName ?? this.authorName,
      likeCount: likeCount ?? this.likeCount,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      originalUrl: originalUrl ?? this.originalUrl,
      noWatermarkUrl: noWatermarkUrl ?? this.noWatermarkUrl,
      timestamp: timestamp ?? this.timestamp,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
} 