import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfileImageCubit extends Cubit<File?> {
  final _picker = ImagePicker();

  ProfileImageCubit() : super(null);

  Future<void> getImage(BuildContext context) async {
    XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      await cropImage(image, context);
    } else {
      String assetPath = 'assets/avatar.png';
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/${assetPath.split('/').last}';
      final file = File(tempPath);
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      emit(file);
    }
  }

  Future<void> cropImage(XFile image, BuildContext context) async {
    var croppedImage = await ImageCropper()
        .cropImage(sourcePath: image.path, aspectRatioPresets: [
      CropAspectRatioPreset.square,
    ], uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop Image',
        toolbarColor: Colors.black,
        toolbarWidgetColor: Colors.white,
        backgroundColor: Colors.white,
        cropFrameColor: Colors.black,
        cropGridColor: Colors.black,
        initAspectRatio: CropAspectRatioPreset.original,
        lockAspectRatio: false,
      ),
      IOSUiSettings(
        title: 'Crop Image',
      ),
      WebUiSettings(
        context: context,
      ),
    ]);

    if (croppedImage != null) {
      File imageFile = File(croppedImage.path);
      emit(imageFile);
    }
  }
}
