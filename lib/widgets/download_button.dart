import 'package:flutter/material.dart';

class DownloadButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDownloading;
  final double progress;
  final IconData icon;
  final String label;

  const DownloadButton({
    super.key,
    required this.onPressed,
    required this.isDownloading,
    required this.progress,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isDownloading ? null : onPressed,
      icon: isDownloading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: progress,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : Icon(icon),
      label: Text(isDownloading ? 'Downloading...' : label),
    );
  }
} 