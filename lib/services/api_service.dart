import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tikup/models/video_model.dart';
import 'package:tikup/utils/constants.dart';

class ApiService {
  static Future<void> initialize() async {
    // Khởi tạo nếu cần
  }

  static Future<VideoModel> getVideoInfo(String url) async {
    try {
      if (!url.contains('tiktok.com')) {
        throw Exception('Invalid TikTok URL');
      }

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiEndpoint}?url=$url'),
        headers: {
          'X-RapidAPI-Host': AppConstants.apiHost,
          'X-RapidAPI-Key': AppConstants.apiKey,
        },
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Kiểm tra response có đúng format không
        if (data['video'] == null || 
            data['music'] == null || 
            data['description'] == null) {
          throw Exception('Invalid API response format');
        }
        
        return VideoModel(
          videoUrl: data['video'][0],
          musicUrl: data['music'][0],
          description: data['description'][0],
          thumbnailUrl: '', // API không trả về thumbnail
          authorName: '', // API không trả về author
          likeCount: 0, // API không trả về like count
          downloadUrl: data['video'][0],
        );
      } else {
        throw Exception('Failed to load video info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }
}