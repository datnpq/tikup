import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:tikup/utils/notification_manager.dart';

class ErrorHandler {
  // Show error dialog with details and retry option
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? retryButtonText,
    VoidCallback? onRetry,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          
          // Retry button (optional)
          if (onRetry != null && retryButtonText != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text(retryButtonText),
            ),
        ],
      ),
    );
  }
  
  // Show error notification with optional retry
  static void showErrorNotification(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    NotificationManager.showError(
      context, 
      message,
      onRetry: onRetry
    );
  }
  
  // Parse API and download errors to user-friendly messages
  static String getMessage(dynamic error) {
    String message = error.toString();
    
    // Clean up common error messages
    if (message.contains('Permission denied')) {
      return 'Permission denied. Please grant storage access in settings.';
    } else if (message.contains('SocketException') || 
               message.contains('Connection refused')) {
      return 'Network error. Please check your internet connection.';
    } else if (message.contains('Not Found') || message.contains('404')) {
      return 'The video could not be found. It may have been deleted or set to private.';
    } else if (message.contains('Timeout')) {
      return 'Request timed out. Please try again.';
    } else if (message.contains('Invalid URL') || message.contains('Bad URL')) {
      return 'Invalid TikTok URL. Please check the link and try again.';
    } else if (message.contains('Storage') || message.contains('space')) {
      return 'Not enough storage space. Please free up some space and try again.';
    }
    
    // Remove exception prefixes for cleaner messages
    message = message.replaceAll('Exception: ', '');
    message = message.replaceAll('Error: ', '');
    
    return message;
  }
  
  // Alias for backward compatibility
  static String getReadableErrorMessage(dynamic error) {
    return getMessage(error);
  }
  
  // Log error to console or analytics service
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    developer.log(
      '[ERROR] $context: ${error.toString()}',
      name: 'TikUP',
      error: error,
      stackTrace: stackTrace
    );
    
    // Here you could also send to a remote logging service like Firebase Crashlytics
    // or Sentry if integrated into the app
  }
} 