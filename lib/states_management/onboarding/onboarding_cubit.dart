import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:chat/chat.dart';

import 'package:english_words/english_words.dart';
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

  Future<void> connect(String name, File profileImage,
      {String? phoneNumber}) async {
    emit(Loading());
    final url = await _imageUploader.uploadImage(profileImage);
    final passphrase = _generateSecurityPassphrase(16);

    final user = User(
        username: name,
        photoUrl: url,
        active: true,
        lastseen: DateTime.now(),
        phoneNumber: phoneNumber,
        passphrase: passphrase);
    final createdUser = await _userService.connect(user);
    createdUser.passphrase = user.passphrase;
    final userJson = {
      'username': createdUser.username,
      'active': true,
      'photoUrl': createdUser.photoUrl,
      'id': createdUser.id,
      'phoneNumber': createdUser.phoneNumber,
      'passphrase': passphrase
    };
    await _localCache.save('USER', userJson);

    var preKeyBundle = await _encryptedUser.createPreKeyBundle();
    await _remoteEncryptionService.storePreKeyBundle(
        createdUser.id, preKeyBundle);

    emit(OnboardingSuccess(createdUser));
  }

  Future<void> deleteAccount() async {
    // deletes account from remote
  }

  // Future<void> recover(String name, File profileImage,
  //     {String? phoneNumber}) async {
  //   emit(Loading());
  //   final url = await _imageUploader.uploadImage(profileImage);
  //   final user = await _userService.fetch(id);
  //   _userService.update(user)
  //   final userJson = {
  //     'username': user.username,
  //     'active': true,
  //     'photoUrl': photoUrl,
  //     'id': user.id,
  //     'phoneNumber': user.phoneNumber,
  //     'passphrase': passphrase
  //   };
  //   await _localCache.save('USER', userJson);
  //   createdUser.passphrase = passphrase;

  //   var preKeyBundle = await _encryptedUser.createPreKeyBundle();
  //   await _remoteEncryptionService.storePreKeyBundle(
  //       createdUser.id, preKeyBundle);

  //   emit(OnboardingSuccess(createdUser));
  // }

  String _generateSecurityPassphrase(int wordCount) {
    List<String> selectedWords = [];
    for (int i = 0; i < wordCount; i++) {
      selectedWords.add(WordPair.random().asLowerCase);
    }
    return selectedWords.join(' ');
  }
}
