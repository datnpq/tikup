import 'package:flutter/material.dart';
import 'package:tikup/theme/app_theme.dart';
import 'package:tikup/screens/main_screen.dart';

class TikUpApp extends StatelessWidget {
  const TikUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikUP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}