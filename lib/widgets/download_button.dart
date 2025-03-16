import 'package:flutter/material.dart';

class DownloadButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDownloading;
  final IconData icon;
  final String label;

  const DownloadButton({
    super.key,
    required this.onPressed,
    required this.isDownloading,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isDownloading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                strokeWidth: 2.0,
              ),
            )
          : Icon(icon),
      label: Text(isDownloading ? 'Downloading...' : label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDownloading ? Colors.grey[400] : Theme.of(context).primaryColor,
        disabledBackgroundColor: Colors.grey[400],
        disabledForegroundColor: Colors.white70,
      ),
    );
  }
} 