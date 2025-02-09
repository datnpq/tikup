import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> initialize() async {
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    try {
      // Xin quyền thông báo
      final notificationStatus = await Permission.notification.request();
      
      // Xin quyền tracking trên iOS
      if (Platform.isIOS) {
        await Permission.appTrackingTransparency.request();
      }

      // Xin quyền lưu trữ và Photos
      await Future.wait([
        Permission.storage.request(),
        Permission.photos.request(),
      ]);

    } catch (e) {
      print('Permission request error: $e');
    }
  }

  static Future<bool> checkPhotoPermission() async {
    final status = await Permission.photos.status;
    if (!status.isGranted) {
      final request = await Permission.photos.request();
      return request.isGranted;
    }
    return true;
  }

  static Future<bool> checkStoragePermission() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      final request = await Permission.storage.request();
      return request.isGranted;
    }
    return true;
  }
}