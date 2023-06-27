import 'dart:async';
import 'dart:io';

import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:flutter_chat_app/theme.dart';
import 'package:flutter_chat_app/ui/pages/home/home_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrCodeScanner extends StatefulWidget {
  final IUserService userService;
  final User me;
  final IHomeRouter router;
  const QrCodeScanner(this.userService, this.me, this.router, {super.key});

  @override
  State<QrCodeScanner> createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedUid;
  bool isPermissionGranted = false;
  bool showInputField = false;
  User? foundUser;
  bool _timerExpired = false;
  final TextEditingController _textEditingController = TextEditingController();
  late Timer timer;
  @override
  void initState() {
    super.initState();
    _getCameraPermission();
    _startTimer();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
                flex: 4,
                child: isPermissionGranted
                    ? Stack(
                        children: [
                          QRView(
                            key: qrKey,
                            onQRViewCreated: _onQRViewCreated,
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              icon: Icon(Icons.flash_on,
                                  color: kPrimary, size: 30),
                              onPressed: () {
                                controller!.toggleFlash();
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: IconButton(
                              icon: Icon(
                                Icons.flip_camera_android_rounded,
                                color: kPrimary,
                                size: 30,
                              ),
                              onPressed: () {
                                controller!.flipCamera();
                              },
                            ),
                          )
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Text(
                            'Please grant camera permission to continue.',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                      )),
            SingleChildScrollView(
              child: Center(
                child: _timerExpired
                    ? Column(
                        children: [
                          SizedBox(height: 20),
                          Text(
                              'Not working? Paste the user ID to start a secure communication:',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 5,
                              ),
                              Expanded(child: _buildAddUserInput(context)),
                              IconButton(
                                  onPressed: () {
                                    _routeToMessageThread(
                                        _textEditingController.text.trim());
                                  },
                                  icon: Icon(
                                    Icons.add_rounded,
                                    color: kPrimary,
                                  ))
                            ],
                          )
                        ],
                      )
                    : scannedUid == null
                        // no barcode scanned
                        ? Container(
                            margin: EdgeInsets.only(
                                top: 50, left: 8, right: 8, bottom: 8),
                            child: Text(
                                'Scan the QR code of your friends to add them to your contacts list',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                          )
                        : // barcode scanned but invalid
                        Container(
                            margin: EdgeInsets.only(
                                top: 50, left: 8, right: 8, bottom: 8),
                            child: Text('Invalid user',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                          ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  _startTimer() {
    _timerExpired = false;
    timer = Timer(const Duration(seconds: 10), () {
      setState(() {
        _timerExpired = true;
      });
    });
  }

  Future<void> _getCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      isPermissionGranted = await Permission.camera.request().isGranted;
    } else {
      isPermissionGranted = true;
    }
    setState(() {});
  }

  void _onQRViewCreated(QRViewController controller) {
    bool isProcessing = false;
    if (isPermissionGranted) {
      this.controller = controller;
      controller.resumeCamera();
      controller.scannedDataStream.listen((scanData) async {
        if (!isProcessing) {
          isProcessing = true;
          scannedUid = scanData.code;
          controller.pauseCamera();
          await _routeToMessageThread(scannedUid);
          isProcessing = false;
        }
      });
    } else {
      _getCameraPermission;
    }
  }

  Future<void> _routeToMessageThread(String? userId) async {
    scannedUid = userId;
    if (userId == null) return;
    if (userId.isEmpty) return;
    try {
      foundUser = await widget.userService.fetch(userId);

      if (foundUser != null) {
        print(foundUser!.toJson());
        await widget.router.onShowMessageThread(context, foundUser!, widget.me);
        Navigator.pop(context);
      } else {
        controller!.resumeCamera();
        timer.cancel();
        _startTimer();
        setState(() {});
      }
    } catch (e) {
      setState(() {});
    }
  }

  _buildAddUserInput(BuildContext context) {
    final border = OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(90.0)),
        borderSide: isLightTheme(context)
            ? BorderSide.none
            : BorderSide(color: Colors.grey.withOpacity(0.3)));
    return TextFormField(
      controller: _textEditingController,
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      style: Theme.of(context).textTheme.bodySmall,
      cursorColor: kPrimary,
      decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          enabledBorder: border,
          filled: true,
          fillColor:
              isLightTheme(context) ? kPrimary.withOpacity(0.1) : kBubbleDark,
          focusedBorder: border),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    timer.cancel();
    super.dispose();
  }
}
