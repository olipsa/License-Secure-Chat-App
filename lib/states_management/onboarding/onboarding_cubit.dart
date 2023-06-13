import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:chat/chat.dart';
import 'package:flutter_chat_app/cache/local_cache.dart';
import 'package:flutter_chat_app/data/services/image_uploader.dart';
import 'package:flutter_chat_app/models/encrypted_user.dart';
import 'package:flutter_chat_app/states_management/onboarding/onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final IUserService _userService;
  final ImageUploader _imageUploader;
  final ILocalCache _localCache;
  final IRemoteEncryptionService _remoteEncryptionService;
  final EncryptedUser _encryptedUser;

  OnboardingCubit(this._userService, this._imageUploader, this._localCache,
      this._remoteEncryptionService, this._encryptedUser)
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

    await _encryptedUser.initEncryptedUser(createdUser.id);
    _encryptedUser.createPreKeyBundle();
    await _remoteEncryptionService.storePreKeyBundle(
        createdUser.id, _encryptedUser.preKeyBundle);

    emit(OnboardingSuccess(createdUser));
  }
}
