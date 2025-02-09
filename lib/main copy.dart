import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tikup/app.dart';

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

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikUP',
      theme: ThemeData.dark().copyWith(
        // Màu sắc chính
        primaryColor: Color(0xFF00F2EA), // Màu cyan của TikTok
        scaffoldBackgroundColor: Color(0xFF121212),
        
        // Card Theme
        cardTheme: CardTheme(
          color: Color(0xFF1E1E1E),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // AppBar Theme
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

        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Color(0xFF00F2EA),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // Text Theme
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Colors.white,
            fontSize: 24,
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

        // Input Decoration Theme
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

        // Elevated Button Theme
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

        // Icon Theme
        iconTheme: IconThemeData(
          color: Color(0xFF00F2EA),
          size: 24,
        ),
      ),
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: 24),
                Text(
                  'TikUP',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _pages = [
    TikTokDownloader(),
    BookmarksScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class TikTokDownloader extends StatefulWidget {
  @override
  _TikTokDownloaderState createState() => _TikTokDownloaderState();
}

class _TikTokDownloaderState extends State<TikTokDownloader> {
  final TextEditingController _urlController = TextEditingController();
  String? videoUrl;
  String? musicUrl;
  String? description;
  bool isLoading = false;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> fetchVideo(String url) async {
    setState(() {
      isLoading = true;
      videoUrl = null;
      musicUrl = null;
      description = null;
    });

    try {
      // Xử lý URL để lấy video ID
      String videoId = url;
      if (url.contains('tiktok.com')) {
        final uri = Uri.parse(url);
        videoId = uri.pathSegments.last;
      }

      final response = await http.get(
        Uri.parse('https://tiktok-full-info-without-watermark.p.rapidapi.com/vid/index?url=https://www.tiktok.com/@user/video/$videoId'),
        headers: {
          'X-RapidAPI-Host': 'tiktok-full-info-without-watermark.p.rapidapi.com',
          'X-RapidAPI-Key': 'ca6181bda3msh7d3414d442373d2p1d915bjsnd909d7fb935b', // API key từ PHP code của bạn
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['error'] != null) {
          throw Exception(data['error']);
        }
        
        setState(() {
          videoUrl = data['video']?[0];
          musicUrl = data['music']?[0];
          description = data['description']?[0];
          isLoading = false;
        });

        // Khởi tạo video player nếu có URL
        if (videoUrl != null) {
          await initializeVideoPlayer(videoUrl!);
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> initializeVideoPlayer(String url) async {
    try {
      _videoPlayerController?.dispose();
      _chewieController?.dispose();

      _videoPlayerController = VideoPlayerController.network(url);
      await _videoPlayerController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: 9/16,
        autoPlay: true,
        looping: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Lỗi phát video: $errorMessage',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );
    } catch (e) {
      print('Video player initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border),
            SizedBox(width: 8),
            Text('TikUP'),
          ],
        ),
        actions: [
          if (isLoading)
            Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: isLoading ? null : () {
              if (_urlController.text.isNotEmpty) {
                fetchTikUpVideo(_urlController.text);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please insert TikTok Video Link or username',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 24),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'https://vm.tiktok.com/...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => fetchVideo(_urlController.text),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Find'),
                    SizedBox(width: 8),
                    Icon(Icons.search, size: 20),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56),
                ),
              ),
              if (isLoading)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (videoUrl != null) ...[
                SizedBox(height: 20),
                if (_chewieController != null)
                  AspectRatio(
                    aspectRatio: 9/16,
                    child: Chewie(controller: _chewieController!),
                  ),
                SizedBox(height: 16),
                Text(
                  description ?? '',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _downloadFile(videoUrl!, 'video.mp4'),
                      icon: Icon(Icons.video_library),
                      label: Text('Tải Video'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _downloadFile(musicUrl!, 'audio.mp3'),
                      icon: Icon(Icons.music_note),
                      label: Text('Tải Nhạc'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadFile(String url, String filename) async {
    // TODO: Implement file download logic
    // Có thể sử dụng package như dio hoặc flutter_downloader
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đang tải xuống $filename...')),
    );
  }
}

class BookmarksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collections'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                Icons.bookmark_border,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              "You haven't bookmarked yet!",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                Icons.history,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              "You haven't saved yet!",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Title', style: Theme.of(context).textTheme.headlineMedium),
            // ...
          ],
        ),
      ),
    );
  }
}
