import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageCubit extends Cubit<File?> {
  final _picker = ImagePicker();

  ProfileImageCubit() : super(null);

  Future<void> getImage(BuildContext context) async {
    XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      await cropImage(image, context);
    }
  }

  Future<void> cropImage(XFile image, BuildContext context) async {
    ImageCropper cropper = ImageCropper();
    File? croppedImage = await cropper.cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(
        ratioX: 1, // Set the aspect ratio to 1:1 for a square format
        ratioY: 1,
      ),
      compressQuality: 50,
      maxWidth: 1000,
      maxHeight: 1000,
      androidUiSettings: const AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: kPrimary,
          toolbarWidgetColor: Colors.black,
          backgroundColor: Colors.white,
          activeControlsWidgetColor: kPrimary),
    );

    if (croppedImage != null) {
      emit(croppedImage);
    }
  }
}
