import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageCubit extends Cubit<File?> {
  final _picker = ImagePicker();

  ProfileImageCubit() : super(null);

  Future<void> getImage() async {
    XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image == null) return;
    emit(File(image.path));
  }
}
