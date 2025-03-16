import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tikup/services/download_service.dart';
import 'package:tikup/services/api_service.dart';
import 'package:tikup/services/history_service.dart';
import 'package:tikup/utils/notification_manager.dart';
import 'package:tikup/utils/error_handler.dart';
import 'package:tikup/widgets/banner_ad_widget.dart';
import 'package:tikup/services/ad_service.dart';

class BatchDownloadScreen extends StatefulWidget {
  const BatchDownloadScreen({Key? key}) : super(key: key);

  @override
  State<BatchDownloadScreen> createState() => _BatchDownloadScreenState();
}

class _BatchDownloadScreenState extends State<BatchDownloadScreen> {
  final TextEditingController _urlsController = TextEditingController();
  final List<_BatchDownloadItem> _downloadItems = [];
  bool _isProcessing = false;
  int _totalUrls = 0;
  int _successCount = 0;
  int _failedCount = 0;
  final AdService _adService = AdService();
  
  @override
  void dispose() {
    _urlsController.dispose();
    super.dispose();
  }
  
  void _processUrls() {
    if (_isProcessing) return;
    
    final text = _urlsController.text.trim();
    if (text.isEmpty) {
      NotificationManager.showError(
        context, 
        'Please enter at least one TikTok URL',
      );
      return;
    }
    
    // Extract URLs from the text
    final RegExp urlRegex = RegExp(
      r'https?:\/\/(?:www\.)?(?:tiktok\.com|vm\.tiktok\.com)\/[^\s]+',
      caseSensitive: false,
    );
    
    final matches = urlRegex.allMatches(text);
    final urls = matches.map((match) => match.group(0)!).toList();
    
    if (urls.isEmpty) {
      NotificationManager.showError(
        context, 
        'No valid TikTok URLs found',
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _totalUrls = urls.length;
      _successCount = 0;
      _failedCount = 0;
      _downloadItems.clear();
      
      // Create download items
      for (final url in urls) {
        _downloadItems.add(_BatchDownloadItem(
          url: url,
          status: _DownloadStatus.pending,
        ));
      }
    });
    
    // Start downloading
    _startDownloads();
  }
  
  Future<void> _startDownloads() async {
    final downloadService = DownloadService();
    
    for (int i = 0; i < _downloadItems.length; i++) {
      if (!mounted) return;
      
      final item = _downloadItems[i];
      
      setState(() {
        item.status = _DownloadStatus.downloading;
      });
      
      try {
        await downloadService.downloadFromUrl(
          item.url,
          (progress) {
            if (!mounted) return;
            setState(() {
              item.progress = progress;
            });
          },
        );
        
        if (!mounted) return;
        
        setState(() {
          item.status = _DownloadStatus.completed;
          _successCount++;
        });
      } catch (e) {
        if (!mounted) return;
        
        setState(() {
          item.status = _DownloadStatus.failed;
          item.error = ErrorHandler.getReadableErrorMessage(e);
          _failedCount++;
        });
      }
    }
    
    if (!mounted) return;
    
    setState(() {
      _isProcessing = false;
    });
    
    // Show completion notification
    if (_successCount > 0) {
      NotificationManager.showSuccess(
        context, 
        'Downloaded $_successCount of $_totalUrls videos',
      );
    } else {
      NotificationManager.showError(
        context, 
        'Failed to download any videos',
      );
    }
  }
  
  void _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      setState(() {
        _urlsController.text = clipboardData.text!;
      });
    }
  }
  
  void _clearAll() {
    setState(() {
      _urlsController.clear();
      _downloadItems.clear();
      _totalUrls = 0;
      _successCount = 0;
      _failedCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Batch Download'),
        actions: [
          if (_downloadItems.isNotEmpty && !_isProcessing)
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: _clearAll,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: Column(
        children: [
          // Input area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter TikTok URLs (one per line or separated by space)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _urlsController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'https://www.tiktok.com/...\nhttps://vm.tiktok.com/...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(16),
                    ),
                    enabled: !_isProcessing,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: !_isProcessing ? _processUrls : null,
                        icon: Icon(_isProcessing ? Icons.hourglass_empty : Icons.download),
                        label: Text(_isProcessing ? 'Downloading...' : 'Start Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: !_isProcessing ? _pasteFromClipboard : null,
                      icon: Icon(Icons.paste),
                      tooltip: 'Paste from clipboard',
                      color: Colors.cyan,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status summary
          if (_downloadItems.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Text(
                    'Total: $_totalUrls',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 16),
                  if (_successCount > 0)
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text('$_successCount'),
                      ],
                    ),
                  SizedBox(width: 16),
                  if (_failedCount > 0)
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 16),
                        SizedBox(width: 4),
                        Text('$_failedCount'),
                      ],
                    ),
                ],
              ),
            ),
          
          // Download items list
          Expanded(
            child: _downloadItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _downloadItems.length,
                    padding: EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final item = _downloadItems[index];
                      return _buildDownloadItem(item, index);
                    },
                  ),
          ),
          
          // Banner ad - only show if not premium
          if (!_adService.isPremium) BannerAdWidget(),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.format_list_bulleted,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Batch Download',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Enter multiple TikTok URLs to download them all at once',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDownloadItem(_BatchDownloadItem item, int index) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (item.status) {
      case _DownloadStatus.pending:
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Pending';
        break;
      case _DownloadStatus.downloading:
        statusColor = Colors.blue;
        statusIcon = Icons.download;
        statusText = 'Downloading ${(item.progress * 100).toStringAsFixed(0)}%';
        break;
      case _DownloadStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case _DownloadStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Failed';
        break;
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 16),
                SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (item.status == _DownloadStatus.downloading)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  value: item.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                ),
              ),
            if (item.status == _DownloadStatus.failed && item.error != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  item.error!,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
}

class _BatchDownloadItem {
  final String url;
  _DownloadStatus status;
  double progress;
  String? error;
  
  _BatchDownloadItem({
    required this.url,
    required this.status,
    this.progress = 0.0,
    this.error,
  });
} 