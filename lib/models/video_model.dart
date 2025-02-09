class VideoModel {
  final String videoUrl;
  final String musicUrl;
  final String description;
  final String thumbnailUrl;
  final String authorName;
  final int likeCount;
  final String downloadUrl;

  VideoModel({
    required this.videoUrl,
    required this.musicUrl,
    required this.description,
    this.thumbnailUrl = '',
    this.authorName = '',
    this.likeCount = 0,
    required this.downloadUrl,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      videoUrl: json['video'][0],
      musicUrl: json['music'][0], 
      description: json['description'][0],
      downloadUrl: json['video'][0],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoUrl': videoUrl,
      'musicUrl': musicUrl,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'authorName': authorName,
      'likeCount': likeCount,
      'downloadUrl': downloadUrl,
    };
  }
} 