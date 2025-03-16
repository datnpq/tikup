import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';

class PermissionService {
  // Keep initialize static for compatibility with main.dart
  static Future<void> initialize() async {
    // Initialize permissions logic if needed
    await PermissionService().requestAllPermissions();
  }
  
  // Private constructor
  PermissionService._privateConstructor();
  
  // Singleton instance
  static final PermissionService _instance = PermissionService._privateConstructor();
  
  // Factory constructor to return the same instance
  factory PermissionService() {
    return _instance;
  }
  
  // Request all permissions needed by the app
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    List<Permission> permissions = [];
    
    if (Platform.isAndroid) {
      permissions = [
        Permission.storage,
        // For Android 13+ we use these more specific permissions
        if (_getAndroidVersion() >= 13)
          Permission.photos,
        if (_getAndroidVersion() >= 13)
          Permission.videos,
        Permission.mediaLibrary,
      ];
    } else if (Platform.isIOS) {
      permissions = [
        Permission.photos,
        Permission.mediaLibrary,
      ];
    }
    
    // Request all permissions at once
    return await permissions.request();
  }
  
  // Check if we have all needed permissions
  static Future<bool> hasRequiredPermissions() async {
    return await PermissionService().hasRequiredPermissionsInternal();
  }
  
  Future<bool> hasRequiredPermissionsInternal() async {
    if (Platform.isAndroid) {
      if (_getAndroidVersion() >= 13) {
        return await Permission.photos.isGranted && 
               await Permission.videos.isGranted;
      } else {
        return await Permission.storage.isGranted;
      }
    } else if (Platform.isIOS) {
      return await Permission.photos.isGranted;
    }
    return false;
  }
  
  // Show permission settings dialog
  Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text('TikUp needs storage permissions to download and save videos. Please grant these permissions in Settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not Now'),
          ),
        ],
      ),
    );
  }

  Future<bool> checkPhotoPermission() async {
    final status = await Permission.photos.status;
    if (!status.isGranted) {
      final request = await Permission.photos.request();
      return request.isGranted;
    }
    return true;
  }

  // Get Android SDK version safely
  int _getAndroidVersion() {
    try {
      if (Platform.isAndroid) {
        final String version = Platform.operatingSystemVersion;
        final List<String> parts = version.split('.');
        if (parts.isNotEmpty) {
          return int.tryParse(parts[0]) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> checkStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) {
        return true;
      }
      
      // For Android 13+ we need different permissions
      int androidVersion = _getAndroidVersion();
      if (androidVersion >= 13) {
        bool photosGranted = await Permission.photos.isGranted;
        bool videosGranted = await Permission.videos.isGranted;
        return photosGranted && videosGranted;
      } else {
        return await Permission.storage.isGranted;
      }
    } else if (Platform.isIOS) {
      return await Permission.photos.isGranted;
    }
    
    return false;
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isIOS) {
      // On iOS we need Photos permission
      PermissionStatus photoStatus = await Permission.photos.request();
      
      // Return true if permission is granted
      return photoStatus.isGranted;
    } else {
      // On Android
      if (await Permission.storage.isGranted) {
        return true;
      }
      
      PermissionStatus status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        // User has permanently denied, suggest opening settings
        return false;
      }
      
      return status.isGranted;
    }
  }
}