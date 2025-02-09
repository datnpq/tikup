import 'package:flutter/material.dart';
import 'package:tikup/screens/welcome_screen.dart';

class TikUpApp extends StatelessWidget {
  const TikUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikUP',
      theme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFF00F2EA), // Màu cyan của TikTok
        scaffoldBackgroundColor: Color(0xFF121212),
        
        cardTheme: CardTheme(
          color: Color(0xFF1E1E1E),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(
            color: Color(0xFF00F2EA),
          ),
        ),

        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Color(0xFF00F2EA),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        textTheme: TextTheme(
          headlineLarge: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey[600]),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF00F2EA),
            foregroundColor: Colors.black,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        iconTheme: IconThemeData(
          color: Color(0xFF00F2EA),
          size: 24,
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}