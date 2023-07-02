// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:chat/chat.dart';
import 'package:flutter_chat_app/theme.dart';
import 'package:flutter_chat_app/ui/pages/message_thread/message_thread_router.dart';
import 'package:flutter_chat_app/ui/pages/camera/flashlight_button.dart';
import 'package:image/image.dart' as img;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final User me;
  final User receiver;
  final IMessageThreadRouter router;

  const CameraScreen(this.camera, this.me, this.receiver, this.router,
      {super.key});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isImageCapturing = false;
  bool _isRecording = false;
  String? _videoPath;
  String? _photoPath;
  String? chatId;

  @override
  void initState() {
    super.initState();
    chatId = widget.receiver.id;
    _initializeControllerFuture = initializeCamera();
  }

  Future<void> initializeCamera() async {
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    return _controller.initialize();
  }

  void _flipCamera() async {
    if (!_controller.value.isInitialized) {
      return;
    }
    final cameras = await availableCameras();
    final currentCamera = _controller.description;
    final newCamera = cameras.firstWhere(
        (camera) => camera.lensDirection != currentCamera.lensDirection);

    await _controller.dispose();

    _controller = CameraController(
      newCamera,
      ResolutionPreset.ultraHigh,
    );

    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  Future<String> _flipImageIfNeeded(String imagePath) async {
    final originalFile = File(imagePath);
    final originalBytes = await originalFile.readAsBytes();
    final originalImage = img.decodeImage(originalBytes);

    img.Image orientedImage;

    if (_controller.value.description.lensDirection ==
        CameraLensDirection.front) {
      orientedImage = img.flipHorizontal(originalImage!);
      final orientedBytes = img.encodeJpg(orientedImage, quality: 90);
      final orientedFile =
          await originalFile.writeAsBytes(orientedBytes, flush: true);

      return orientedFile.path;
    } else if (_controller.value.description.lensDirection ==
        CameraLensDirection.back) {}
    return originalFile.path;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              actions: [
                FlashlightButton(_controller),
              ],
            ),
            body: Stack(children: [
              AspectRatio(
                aspectRatio: 8.6 / 15,
                child: _controller.value.isInitialized
                    ? CameraPreview(_controller)
                    : Container(), // Placeholder widget when camera is not available
              ),
              if (_isRecording)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    children: [
                      Icon(Icons.fiber_manual_record, color: Colors.red),
                      Text(
                        "Recording",
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    ],
                  ),
                ),
            ]),
            floatingActionButton: Container(
              decoration: BoxDecoration(
                  color: isLightTheme(context)
                      ? kPrimary.withOpacity(0.1)
                      : kBubbleDark),
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'button_gallery',
                    backgroundColor: kPrimary,
                    child: const Icon(Icons.photo_library_rounded),
                    onPressed: () {
                      _openGallery();
                    },
                  ),
                  GestureDetector(
                    onLongPress: () {
                      if (!_isRecording) {
                        _startVideoRecording();
                      }
                    },
                    onLongPressEnd: (details) {
                      if (_isRecording) {
                        _stopVideoRecording();
                      }
                    },
                    child: Transform.scale(
                      scale: _isRecording ? 1.4 : 1.0,
                      child: FloatingActionButton(
                        heroTag: 'button_camera',
                        backgroundColor: kPrimary,
                        child: _isImageCapturing
                            ? const CircularProgressIndicator(
                                color: Colors.black,
                              )
                            : const Icon(Icons.camera),
                        onPressed: () async {
                          if (!_isImageCapturing) _captureImage();
                        },
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    heroTag: 'button_flip_camera',
                    backgroundColor: kPrimary,
                    child: const Icon(Icons.flip_camera_android_rounded),
                    onPressed: () {
                      _flipCamera();
                    },
                  ),
                ],
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  void _openGallery() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      widget.router.onShowPicturePreview(
          context, widget.receiver, widget.me, pickedImage.path);
    }
  }

  void _captureImage() async {
    if (_isRecording) return;
    setState(() {
      _isImageCapturing = true;
    });

    try {
      final image = await _controller.takePicture();
      final flippedImagePath = await _flipImageIfNeeded(image.path);

      // Process the captured image
      setState(() {
        _isImageCapturing = false;
        _photoPath = flippedImagePath;
      });
    } catch (e) {
      // Handle any errors that occur during image capture

      setState(() {
        _isImageCapturing = false;
      });
    }
    if (_photoPath != null && !_isRecording) {
      widget.router.onShowPicturePreview(
          context, widget.receiver, widget.me, _photoPath);
    }
  }

  Future<void> _startVideoRecording() async {
    if (!_controller.value.isInitialized) {
      return;
    }
    try {
      await _initializeControllerFuture;
      await _controller.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } on CameraException catch (e) {
      print(e);
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_controller.value.isRecordingVideo) {
      return;
    }

    late XFile video;

    try {
      video = await _controller.stopVideoRecording();
    } on CameraException catch (e) {
      print(e);
    } finally {
      setState(() {
        _isRecording = false;
        _videoPath = video.path;
      });
    }

    if (_videoPath != null) {
      widget.router
          .onShowVideoPreview(context, widget.receiver, widget.me, _videoPath);
    }
  }
}
