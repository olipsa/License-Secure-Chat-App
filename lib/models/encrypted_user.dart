// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class EncryptedUser {
  late IdentityKeyPair identityKeyPair;
  late int registrationId;
  late int deviceId;
  late InMemoryIdentityKeyStore identityKeyStore;
  late InMemoryPreKeyStore preKeyStore;
  late InMemorySignedPreKeyStore signedPreKeyStore;
  late InMemorySessionStore sessionStore;

  late List<PreKeyRecord> preKeys;
  late SignedPreKeyRecord signedPreKey;
  late PreKeyBundle preKeyBundle;

  EncryptedUser();

  Future<void> initEncryptedUser(String? userId) async {
    identityKeyPair = generateIdentityKeyPair();
    registrationId = generateRegistrationId(false);
    identityKeyStore =
        InMemoryIdentityKeyStore(identityKeyPair, registrationId);

    String? deviceIdString = await _getDeviceId();
    deviceId = int.parse(deviceIdString!.replaceAll(RegExp(r'[^\d]'), ''));

    preKeyStore = InMemoryPreKeyStore();
    signedPreKeyStore = InMemorySignedPreKeyStore();
    sessionStore = InMemorySessionStore();
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

  createPreKeyBundle() {
    // one-time pre-keys -> OTPKs
    int preKeyId = 0;
    preKeys = generatePreKeys(preKeyId, 110);

    // Find the pre-key with the matching ID from the preKeys list
    late PreKeyRecord matchingPreKey;
    for (PreKeyRecord preKey in preKeys) {
      preKeyStore.storePreKey(preKey.id, preKey);
      if (preKey.id == preKeyId) {
        matchingPreKey = preKey;
        break;
      }
    }

    int signedPreKeyId = 0;
    signedPreKey = generateSignedPreKey(identityKeyPair, signedPreKeyId);
    signedPreKeyStore.storeSignedPreKey(signedPreKeyId, signedPreKey);

    preKeyBundle = PreKeyBundle(
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
