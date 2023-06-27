import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class Video extends StatefulWidget {
  final String videoPath;

  Video({required this.videoPath});

  @override
  _VideoState createState() => _VideoState();
}

class _VideoState extends State<Video> {
  String? _thumbnailData;
  VideoPlayerController? _videoPlayerController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    _thumbnailData = await VideoThumbnail.thumbnailFile(
      video: widget.videoPath,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 128,
      quality: 25,
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleVideoPlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _thumbnailData != null
              ? Image.file(
                  File(_thumbnailData!),
                  fit: BoxFit.cover,
                )
              : CircularProgressIndicator(),
          if (!_isPlaying)
            Icon(
              Icons.play_circle_outline,
              size: 48,
              color: Colors.white,
            ),
          if (_isPlaying && _videoPlayerController != null)
            AspectRatio(
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              child: VideoPlayer(_videoPlayerController!),
            ),
        ],
      ),
    );
  }

  void _toggleVideoPlayback() {
    if (_videoPlayerController == null) {
      _videoPlayerController =
          VideoPlayerController.file(File(widget.videoPath))
            ..initialize().then((_) {
              setState(() {
                _isPlaying = true;
              });
              _videoPlayerController!.play();
              _handleVideoEnd();
            });
    } else {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        _videoPlayerController!.play();
        setState(() {
          _isPlaying = true;
        });
      }
      _handleVideoEnd();
    }
  }

  void _handleVideoEnd() async {
    await _videoPlayerController!.setLooping(false);
    await _videoPlayerController!.play();
    await Future.delayed(_videoPlayerController!.value.duration);
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }
}
