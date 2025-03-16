import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tikup/models/video_model.dart';

class HistoryService {
  static const String _historyKey = 'tikup_history';
  static const String _bookmarksKey = 'tikup_bookmarks';
  
  // Using instance variables instead of static
  List<VideoModel> _cachedHistory = [];
  List<VideoModel> _cachedBookmarks = [];
  
  // Private constructor
  HistoryService._privateConstructor();
  
  // Singleton instance
  static final HistoryService _instance = HistoryService._privateConstructor();
  
  // Factory constructor to return the same instance
  factory HistoryService() {
    return _instance;
  }
  
  // Initialize and load data from SharedPreferences
  Future<void> initialize() async {
    await _loadHistory();
    await _loadBookmarks();
  }
  
  // Private method to load history from SharedPreferences
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    
    _cachedHistory = historyJson
        .map((item) => VideoModel.fromJson(json.decode(item)))
        .toList();
    
    // Sort by timestamp descending (newest first)
    _cachedHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  // Private method to load bookmarks from SharedPreferences
  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getStringList(_bookmarksKey) ?? [];
    
    _cachedBookmarks = bookmarksJson
        .map((item) => VideoModel.fromJson(json.decode(item)))
        .toList();
    
    // Sort by timestamp descending (newest first)
    _cachedBookmarks.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  // Private method to save history to SharedPreferences
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _cachedHistory
        .map((item) => json.encode(item.toJson()))
        .toList();
    
    await prefs.setStringList(_historyKey, historyJson);
  }
  
  // Private method to save bookmarks to SharedPreferences
  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = _cachedBookmarks
        .map((item) => json.encode(item.toJson()))
        .toList();
    
    await prefs.setStringList(_bookmarksKey, bookmarksJson);
  }
  
  // Add video to history
  Future<void> addToHistory(VideoModel video) async {
    // Remove if already exists to avoid duplicates
    _cachedHistory.removeWhere((item) => item.id == video.id);
    
    // Add to beginning of list
    _cachedHistory.insert(0, video);
    
    // Limit history to 50 items
    if (_cachedHistory.length > 50) {
      _cachedHistory = _cachedHistory.sublist(0, 50);
    }
    
    await _saveHistory();
  }
  
  // Get all history items
  List<VideoModel> getHistory() {
    return List.unmodifiable(_cachedHistory);
  }
  
  // Clear all history
  Future<void> clearHistory() async {
    _cachedHistory.clear();
    await _saveHistory();
  }
  
  // Update bookmark status directly
  Future<void> updateVideoBookmarkStatus(String videoId, bool isBookmarked) async {
    // Find in history
    final historyIndex = _cachedHistory.indexWhere((item) => item.id == videoId);
    if (historyIndex >= 0) {
      _cachedHistory[historyIndex] = _cachedHistory[historyIndex].copyWith(isBookmarked: isBookmarked);
    }
    
    // Handle bookmarks collection
    if (isBookmarked) {
      // If not in bookmarks and should be bookmarked, add it
      if (!_cachedBookmarks.any((item) => item.id == videoId)) {
        // Get from history if available
        if (historyIndex >= 0) {
          _cachedBookmarks.insert(0, _cachedHistory[historyIndex]);
        }
      }
    } else {
      // If should not be bookmarked, remove it
      _cachedBookmarks.removeWhere((item) => item.id == videoId);
    }
    
    await _saveBookmarks();
    await _saveHistory();
  }
  
  // Toggle bookmark status (for backward compatibility)
  Future<VideoModel> toggleBookmark(VideoModel video) async {
    final updatedVideo = video.copyWith(isBookmarked: !video.isBookmarked);
    
    await updateVideoBookmarkStatus(video.id, updatedVideo.isBookmarked);
    
    return updatedVideo;
  }
  
  // Get all bookmark items
  List<VideoModel> getBookmarks() {
    return List.unmodifiable(_cachedBookmarks);
  }
  
  // Check if a video is bookmarked
  bool isBookmarked(String videoId) {
    return _cachedBookmarks.any((item) => item.id == videoId);
  }
  
  // Remove a specific video from history
  Future<void> removeFromHistory(String videoId) async {
    _cachedHistory.removeWhere((item) => item.id == videoId);
    await _saveHistory();
  }
  
  // Remove a specific video from bookmarks
  Future<void> removeFromBookmarks(String videoId) async {
    _cachedBookmarks.removeWhere((item) => item.id == videoId);
    await _saveBookmarks();
  }
} 