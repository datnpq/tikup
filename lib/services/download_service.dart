import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tikup/models/video_model.dart';
import 'package:tikup/services/permission_service.dart';
import 'package:tikup/utils/error_handler.dart';

class DownloadService {
  final PermissionService _permissionService = PermissionService();
  final Dio _dio = Dio(); // Create a single Dio instance for better performance

  Future<void> initialize() async {
    // Initialize download service if needed
  }

  Future<void> downloadVideo(
    VideoModel video, 
    Function(double) onProgress
  ) async {
    try {
      // Create a filename based on the video title or ID
      String fileName = '${video.id ?? 'tikup'}_video.mp4';
      fileName = _sanitizeFileName(fileName);

      // Create a temporary file path
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/$fileName';

      // Download the file to temporary storage first with optimized settings
      await _dio.download(
        video.downloadUrl,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 2),
          headers: {
            'Accept': '*/*',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
          },
        ),
      );

      // Save to gallery with optimized settings
      final result = await ImageGallerySaver.saveFile(
        tempPath,
        isReturnPathOfIOS: true,
        name: fileName
      );
      
      if (result['isSuccess'] != true) {
        ErrorHandler.logError('Save to gallery failed', result);
        throw Exception('Failed to save video to gallery: ${result['errorMessage'] ?? 'Unknown error'}');
      }

      // Clean up temporary file
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      ErrorHandler.logError('Download error', e);
      throw Exception('Download Error: $e');
    }
  }

  Future<void> downloadVideoNoLogo(
    VideoModel video, 
    Function(double) onProgress
  ) async {
    try {
      // Create a filename based on the video title or ID
      String fileName = '${video.id ?? 'tikup'}_video_no_logo.mp4';
      fileName = _sanitizeFileName(fileName);

      // Create a temporary file path
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/$fileName';

      // Use the no-watermark URL if available, otherwise use standard URL
      // Note: In a real implementation, you would need to extract the no-watermark URL
      // This is a placeholder - you'll need to implement actual watermark removal or
      // use a specific API endpoint that provides videos without watermarks
      String noLogoUrl = video.noWatermarkUrl ?? video.downloadUrl;
      
      // Download the file to temporary storage first with optimized settings
      await _dio.download(
        noLogoUrl,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 2),
          headers: {
            'Accept': '*/*',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
          },
        ),
      );

      // Save to gallery with optimized settings
      final result = await ImageGallerySaver.saveFile(
        tempPath,
        isReturnPathOfIOS: true,
        name: fileName
      );
      
      if (result['isSuccess'] != true) {
        ErrorHandler.logError('Save to gallery failed', result);
        throw Exception('Failed to save video to gallery: ${result['errorMessage'] ?? 'Unknown error'}');
      }

      // Clean up temporary file
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      ErrorHandler.logError('Download error', e);
      throw Exception('Download Error: $e');
    }
  }

  // Helper method to sanitize filenames
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, fileName.length > 100 ? 100 : fileName.length);
  }
  
  // Method to download a video directly from a URL (for batch downloads)
  Future<void> downloadFromUrl(
    String url, 
    Function(double) onProgress
  ) async {
    try {
      // Check permissions first
      bool hasPermission = await _permissionService.requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }
      
      // Generate a unique filename based on timestamp
      String fileName = 'tikup_${DateTime.now().millisecondsSinceEpoch}.mp4';
      fileName = _sanitizeFileName(fileName);

      // Create a temporary file path
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/$fileName';

      // Download the file to temporary storage first
      await _dio.download(
        url,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 2),
          headers: {
            'Accept': '*/*',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
          },
        ),
      );

      // Save to gallery
      final result = await ImageGallerySaver.saveFile(
        tempPath,
        isReturnPathOfIOS: true,
        name: fileName
      );
      
      if (result['isSuccess'] != true) {
        ErrorHandler.logError('Save to gallery failed', result);
        throw Exception('Failed to save video to gallery: ${result['errorMessage'] ?? 'Unknown error'}');
      }

      // Clean up temporary file
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      ErrorHandler.logError('Download error', e);
      throw Exception('Download Error: $e');
    }
  }
}