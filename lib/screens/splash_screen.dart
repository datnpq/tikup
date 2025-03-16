import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tikup/services/permission_service.dart';
import 'package:tikup/services/api_service.dart';
import 'package:tikup/services/download_service.dart';
import 'package:tikup/services/history_service.dart';
import 'package:tikup/utils/notification_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  
  const SplashScreen({Key? key, required this.nextScreen}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitializing = true;
  String _statusMessage = 'Initializing app...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // First update status
      setState(() {
        _statusMessage = 'Initializing services...';
      });
      
      // Initialize all services using instance methods
      await Future.wait([
        ApiService().initialize(),
        DownloadService().initialize(),
        HistoryService().initialize(),
      ]);
      
      setState(() {
        _isInitializing = false;
        _statusMessage = 'Ready!';
      });
      
      // Navigate to next screen after a short delay
      _navigateToNextScreen();
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }
  
  void _navigateToNextScreen() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => widget.nextScreen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark,
                  color: Colors.cyan,
                  size: 48,
                ),
                SizedBox(width: 16),
                Text(
                  'TikUP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 48),
            
            // Loading indicator or success message
            if (_isInitializing)
              Column(
                children: [
                  CircularProgressIndicator(color: Colors.cyan),
                  SizedBox(height: 24),
                  Text(
                    _statusMessage,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
} 