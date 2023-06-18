import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/colors.dart';

class FlashlightButton extends StatefulWidget {
  CameraController _cameraController;

  FlashlightButton(this._cameraController);

  @override
  _FlashlightButtonState createState() => _FlashlightButtonState();
}

class _FlashlightButtonState extends State<FlashlightButton> {
  bool _isFlashlightOn = false;

  @override
  void initState() {
    widget._cameraController.setFlashMode(FlashMode.off);
    super.initState();
  }

  void _toggleFlashlight() async {
    if (_isFlashlightOn) {
      _isFlashlightOn = false;
      await widget._cameraController.setFlashMode(FlashMode.off);
    } else {
      _isFlashlightOn = true;
      await widget._cameraController.setFlashMode(FlashMode.always);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
          _isFlashlightOn ? Icons.flash_on_rounded : Icons.flash_off_rounded),
      onPressed: _toggleFlashlight,
      color: kPrimary,
    );
  }

  @override
  void dispose() {
    widget._cameraController.dispose();
    super.dispose();
  }
}
