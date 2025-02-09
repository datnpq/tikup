import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () {
              // TODO: Implement clear history
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Coming soon...'),
      ),
    );
  }
} 