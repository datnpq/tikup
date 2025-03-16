import 'package:flutter/material.dart';
import 'package:tikup/models/video_model.dart';
import 'package:tikup/services/history_service.dart';
import 'package:tikup/widgets/video_list_item.dart';
import 'package:tikup/utils/notification_manager.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  List<VideoModel> _history = [];
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
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Small delay to ensure HistoryService is initialized
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    setState(() {
      _history = _historyService.getHistory();
      _isLoading = false;
    });
  }
  
  List<VideoModel> get _filteredHistory {
    if (_searchQuery.isEmpty) {
      return _history;
    }
    
    return _history.where((video) {
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

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      await _historyService.clearHistory();
      NotificationManager.showSuccess(
        context, 
        'History cleared successfully'
      );
      _loadHistory();
    }
  }
  
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Sort History',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.access_time),
                title: Text('Newest First'),
                onTap: () {
                  if (!mounted) {
                    Navigator.pop(context);
                    return;
                  }
                  setState(() {
                    _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.access_time_filled),
                title: Text('Oldest First'),
                onTap: () {
                  if (!mounted) {
                    Navigator.pop(context);
                    return;
                  }
                  setState(() {
                    _history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.bookmark),
                title: Text('Bookmarked First'),
                onTap: () {
                  if (!mounted) {
                    Navigator.pop(context);
                    return;
                  }
                  setState(() {
                    _history.sort((a, b) => b.isBookmarked == a.isBookmarked 
                        ? b.timestamp.compareTo(a.timestamp)
                        : (b.isBookmarked ? 1 : 0) - (a.isBookmarked ? 1 : 0));
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
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
                    hintText: 'Search history...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              )
            : const Text('Download History'),
        actions: [
          // Search toggle button
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
            tooltip: _isSearching ? 'Cancel search' : 'Search history',
          ),
          
          // Sort button
          if (_history.isNotEmpty && !_isSearching)
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: _showSortOptions,
              tooltip: 'Sort history',
            ),
            
          // Clear history button
          if (_history.isNotEmpty && !_isSearching)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: Theme.of(context).primaryColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _history.isEmpty
                ? _buildEmptyState()
                : _filteredHistory.isEmpty
                    ? _buildNoSearchResults()
                    : _buildHistoryList(),
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
              Icons.history,
              size: 64,
              color: Colors.cyan,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Download History',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Videos you download will appear here for easy access',
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
            icon: Icon(Icons.download),
            label: Text('Download Videos'),
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
  
  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredHistory.length,
      itemBuilder: (context, index) {
        final video = _filteredHistory[index];
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
                  'Remove from history',
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
              'Removing from history...',
              duration: Duration(milliseconds: 500),
            );
            return true;
          },
          onDismissed: (direction) async {
            // Remove from history
            await _deleteHistoryItem(video.id);
            
            // Show undo option
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Removed from history'),
                action: SnackBarAction(
                  label: 'UNDO',
                  onPressed: () {
                    // We can't restore the item directly since it requires
                    // re-downloading. Just notify the user.
                    if (context.mounted) {
                      NotificationManager.showInfo(
                        context, 
                        'This function is not available. Please download the video again.'
                      );
                    }
                  },
                ),
              ),
            );
          },
          child: VideoListItem(
            video: video,
            onToggleBookmark: _onToggleBookmark,
            onDelete: () => _confirmDelete(video.id),
          ),
        );
      },
    );
  }
  
  Future<void> _confirmDelete(String videoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove from History'),
        content: Text('Are you sure you want to remove this video from your history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Remove'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      await _deleteHistoryItem(videoId);
    }
  }

  Future<void> _onToggleBookmark(VideoModel video) async {
    final updatedVideo = await _historyService.toggleBookmark(video);
    
    // Show a nice notification
    NotificationManager.showInfo(
      context,
      updatedVideo.isBookmarked 
          ? 'Added to bookmarks' 
          : 'Removed from bookmarks',
    );
    
    // Need to reload the entire history list to avoid "Cannot modify an unmodifiable list" error
    _loadHistory();
  }

  Future<void> _deleteHistoryItem(String videoId) async {
    await _historyService.removeFromHistory(videoId);
    if (!mounted) return;
    _loadHistory();
  }
} 