import 'package:dio/dio.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tikup/services/permission_service.dart';

class DownloadService {
  static final Dio _dio = Dio();
  
  static Future<void> initialize() async {
    // Khởi tạo Dio options nếu cần
  }

  static Future<void> downloadVideo(
    String url, 
    String filename, 
    Function(double) onProgress
  ) async {
    try {
      if (!await PermissionService.checkPhotoPermission()) {
        throw Exception('Permission denied');
      }

      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      final result = await ImageGallerySaver.saveFile(
        response.data,
        name: filename,
        isReturnPathOfIOS: true,
      );

      if (!result['isSuccess']) {
        throw Exception('Failed to save video');
      }
    } catch (e) {
      throw Exception('Download Error: $e');
    }
  }

  static Future<void> downloadAudio(
    String url, 
    String filename,
    Function(double) onProgress
  ) async {
    try {
      if (!await PermissionService.checkStoragePermission()) {
        throw Exception('Permission denied');
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename';

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );
    } catch (e) {
      throw Exception('Download Error: $e');
    }
  }
}