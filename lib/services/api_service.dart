import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tikup/models/video_model.dart';
import 'package:tikup/utils/constants.dart';
import 'package:tikup/utils/connectivity_handler.dart';
import 'dart:io';

class ApiService {
  // Private constructor
  ApiService._privateConstructor();
  
  // Singleton instance
  static final ApiService _instance = ApiService._privateConstructor();
  
  // Factory constructor to return the same instance
  factory ApiService() {
    return _instance;
  }

  Future<void> initialize() async {
    // Initialize if needed
  }

  Future<bool> checkInternetConnection() async {
    return await ConnectivityHandler.isConnected();
  }

  Future<VideoModel> getVideoInfo(String url) async {
    if (!await checkInternetConnection()) {
      throw Exception('No internet connection. Please check your network settings.');
    }

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
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check response format
        if (data['video'] == null || 
            data['music'] == null || 
            data['description'] == null) {
          throw Exception('Invalid API response format');
        }
        
        final String videoId = _extractVideoId(url);
        
        return VideoModel(
          id: videoId,
          videoUrl: data['video'][0],
          musicUrl: data['music'][0],
          description: data['description'][0],
          thumbnailUrl: data['thumbnail'] != null ? data['thumbnail'][0] : '',
          authorName: data['author'] != null ? data['author'][0] : 'TikTok User',
          likeCount: 0, // API doesn't return like count
          downloadUrl: data['video'][0],
          originalUrl: url,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      } else if (response.statusCode == 429) {
        throw Exception('API rate limit exceeded. Please try again later.');
      } else {
        throw Exception('Failed to load video info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }
  
  // Extract video ID from TikTok URL
  String _extractVideoId(String url) {
    try {
      final Uri uri = Uri.parse(url);
      final List<String> pathSegments = uri.pathSegments;
      
      // TikTok URLs are typically in the format: tiktok.com/@username/video/1234567890
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'video' && i + 1 < pathSegments.length) {
          return pathSegments[i + 1];
        }
      }
      
      // Fallback to a hash of the URL if we can't extract the ID
      return url.hashCode.toString();
    } catch (e) {
      return url.hashCode.toString();
    }
  }
}