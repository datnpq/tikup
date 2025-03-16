import 'package:flutter/material.dart';
import 'package:tikup/models/video_model.dart';
import 'package:tikup/services/history_service.dart';
import 'package:tikup/widgets/video_list_item.dart';
import 'package:tikup/utils/notification_manager.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with SingleTickerProviderStateMixin {
  List<VideoModel> _bookmarks = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final HistoryService _historyService = HistoryService();
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _loadBookmarks();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Small delay to ensure HistoryService is initialized
    await Future.delayed(Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    setState(() {
      _bookmarks = _historyService.getBookmarks();
      _isLoading = false;
    });
  }
  
  List<VideoModel> get _filteredBookmarks {
    if (_searchQuery.isEmpty) {
      return _bookmarks;
    }
    
    return _bookmarks.where((video) {
      return video.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             video.authorName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }
  
  void _toggleSearch() {
    if (!mounted) return;
    
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      } else {
        _animationController.forward();
      }
    });
  }
  
  void _clearAllBookmarks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Bookmarks'),
        content: Text('Are you sure you want to remove all bookmarked videos? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Clear All'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      // Remove bookmark status from all videos
      for (var video in _bookmarks) {
        await _historyService.updateVideoBookmarkStatus(video.id, false);
      }
      
      // Reload the list
      await _loadBookmarks();
      
      NotificationManager.showSuccess(context, 'All bookmarks cleared');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
            ? SizeTransition(
                sizeFactor: _animationController,
                axis: Axis.horizontal,
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search bookmarks...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: TextStyle(color: Colors.white),
                  onChanged: (value) {
                    if (!mounted) return;
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              )
            : Text('Bookmarks'),
        actions: [
          // Search toggle button
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
            tooltip: _isSearching ? 'Cancel search' : 'Search bookmarks',
          ),
          
          // Clear all button (only if there are bookmarks and not searching)
          if (_bookmarks.isNotEmpty && !_isSearching)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              onPressed: _clearAllBookmarks,
              tooltip: 'Clear all bookmarks',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookmarks,
        color: Theme.of(context).primaryColor,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _bookmarks.isEmpty
                ? _buildEmptyState()
                : _filteredBookmarks.isEmpty
                    ? _buildNoSearchResults() 
                    : _buildBookmarksList(),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.cyan,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Bookmarks Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Bookmark your favorite videos to access them quickly, even when you\'re offline',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Go back to main screen
            },
            icon: Icon(Icons.home),
            label: Text('Go to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No matches found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              if (!mounted) return;
              setState(() {
                _searchQuery = '';
              });
            },
            icon: Icon(Icons.clear),
            label: Text('Clear Search'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.cyan,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBookmarksList() {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: _filteredBookmarks.length,
      itemBuilder: (context, index) {
        final video = _filteredBookmarks[index];
        return Dismissible(
          key: Key(video.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            color: Colors.red,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Remove from bookmarks',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            // Show animation for user feedback
            NotificationManager.showInfo(
              context, 
              'Removing from bookmarks...',
              duration: Duration(milliseconds: 500),
            );
            return true;
          },
          onDismissed: (direction) async {
            final removedVideo = video;
            
            // Remove from bookmarks
            await _historyService.updateVideoBookmarkStatus(video.id, false);
            
            // Refresh list after a slight delay for nice animation
            await Future.delayed(Duration(milliseconds: 300));
            if (!mounted) return;
            _loadBookmarks();
            
            // Show undo option
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Removed from bookmarks'),
                action: SnackBarAction(
                  label: 'UNDO',
                  onPressed: () async {
                    // Restore bookmark status
                    await _historyService.updateVideoBookmarkStatus(removedVideo.id, true);
                    if (!mounted) return;
                    _loadBookmarks();
                  },
                ),
              ),
            );
          },
          child: VideoListItem(
            video: video,
            onToggleBookmark: _onToggleBookmark,
            onDelete: null, // No direct delete from bookmarks
          ),
        );
      },
    );
  }

  Future<void> _onToggleBookmark(VideoModel video) async {
    await _historyService.toggleBookmark(video);
    if (!mounted) return;
    _loadBookmarks();
  }
} 