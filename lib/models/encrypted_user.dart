import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_chat_app/data/encrypted_storage/sqflite_identity_key_store.dart';
import 'package:flutter_chat_app/data/encrypted_storage/sqflite_pre_key_store.dart';
import 'package:flutter_chat_app/data/encrypted_storage/sqflite_session_store.dart';
import 'package:flutter_chat_app/data/encrypted_storage/sqflite_signed_pre_key_store.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:sqflite/sqflite.dart';

class EncryptedUser {
  Database db;
  late int deviceId;
  late SqfliteIdentityKeyStore identityKeyStore;
  late SqflitePreKeyKeyStore preKeyStore;
  late SqfliteSignedPreKeyStore signedPreKeyStore;
  late SqfliteSessionStore sessionStore;

  int preKeyId = 0;
  int signedPreKeyId = 0;
  late SignedPreKeyRecord signedPreKey;

  EncryptedUser(this.db);

  Future<void> initEncryptedUser() async {
    identityKeyStore = await SqfliteIdentityKeyStore.create(db);
    preKeyStore = await SqflitePreKeyKeyStore.create(db);
    signedPreKeyStore = await SqfliteSignedPreKeyStore.create(
        db, identityKeyStore.identityKeyPair);
    sessionStore = await SqfliteSessionStore.create(db);

    String? deviceIdString = await _getDeviceId();
    deviceId = int.parse(deviceIdString!.replaceAll(RegExp(r'[^\d]'), ''));
    preKeyId = await preKeyStore.getCurrentPreKeyId();
  }

  Future<String?> _getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // Unique ID on iOS
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.id; // Unique ID on Android
    }
  }

  Future<PreKeyBundle> createPreKeyBundle() async {
    // Called only when user onboarded for the first time

    IdentityKeyPair identityKeyPair = identityKeyStore.identityKeyPair;
    int registrationId = identityKeyStore.localRegistrationId;
    PreKeyRecord matchingPreKey = await preKeyStore.loadPreKey(preKeyId);
    SignedPreKeyRecord signedPreKey =
        await signedPreKeyStore.loadSignedPreKey(signedPreKeyId);

    return PreKeyBundle(
      registrationId,
      deviceId,
      preKeyId,
      matchingPreKey.getKeyPair().publicKey,
      signedPreKeyId,
      signedPreKey.getKeyPair().publicKey,
      signedPreKey.signature,
      identityKeyPair.getPublicKey(),
    );
  }
}
