import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:chat/chat.dart';
import 'package:flutter_chat_app/cache/local_cache.dart';
import 'package:flutter_chat_app/data/services/image_uploader.dart';
import 'package:flutter_chat_app/states_management/onboarding/onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final IUserService _userService;
  final ImageUploader _imageUploader;
  final ILocalCache _localCache;

  OnboardingCubit(this._userService, this._imageUploader, this._localCache)
      : super(OnboardingInitial());

  Future<void> connect(String name, File profileImage) async {
    emit(Loading());
    final url = await _imageUploader.uploadImage(profileImage);
    final user = User(
        username: name, photoUrl: url, active: true, lastseen: DateTime.now());
    final createdUser = await _userService.connect(user);
    final userJson = {
      'username': createdUser.username,
      'active': true,
      'photoUrl': createdUser.photoUrl,
      'id': createdUser.id
    };
    await _localCache.save('USER', userJson);

    await EncryptedUser.initEncryptedUser(createdUser.id);
    EncryptedUser.createPreKeyBundle();
    await _userService.storeKeys(createdUser.id, EncryptedUser.preKeyBundle);

    emit(OnboardingSuccess(createdUser));
  }
}
