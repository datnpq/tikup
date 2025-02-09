import 'package:flutter/material.dart';
import 'package:tikup/app.dart';
import 'package:tikup/services/permission_service.dart';
import 'package:tikup/services/api_service.dart';
import 'package:tikup/services/download_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await initializeServices();
  
  runApp(const TikUpApp());
}

Future<void> initializeServices() async {
  // Initialize permissions
  await PermissionService.initialize();
  
  // Initialize other services
  await Future.wait([
    ApiService.initialize(),
    DownloadService.initialize(),
  ]);
}