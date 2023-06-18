import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FullScreenImage extends StatefulWidget {
  final File imageFile;
  final DateTime timestamp;
  final String? senderUsername;
  const FullScreenImage(
      {super.key,
      required this.imageFile,
      required this.timestamp,
      required this.senderUsername});
  @override
  State<StatefulWidget> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  bool isTitleVisible = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            isTitleVisible = !isTitleVisible;
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'fullScreenImage',
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.cover,
              ),
            ),
            AnimatedOpacity(
              opacity: isTitleVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: AppBar(
                backgroundColor: Colors.black.withOpacity(0.6),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From ${widget.senderUsername}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(widget.timestamp),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime timestamp) {
    String formattedDate;
    DateTime now = DateTime.now();
    DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day) {
      formattedDate = 'Today';
    } else if (timestamp.year == yesterday.year &&
        timestamp.month == yesterday.month &&
        timestamp.day == yesterday.day) {
      formattedDate = 'Yesterday';
    } else {
      formattedDate = DateFormat('EEEE MMMM d, y').format(timestamp);
    }
    formattedDate = '$formattedDate, ${DateFormat('h:mm a').format(timestamp)}';

    return formattedDate;
  }
}
