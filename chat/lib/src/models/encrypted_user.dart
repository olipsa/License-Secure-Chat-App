// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class EncryptedUser {
  static late IdentityKeyPair identityKeyPair;
  static late int registrationId;
  static late int deviceId;
  static late InMemoryIdentityKeyStore identityKeyStore;
  static late InMemoryPreKeyStore preKeyStore;
  static late InMemorySignedPreKeyStore signedPreKeyStore;
  static late InMemorySessionStore sessionStore; // tbd

  static late List<PreKeyRecord> preKeys;
  static late SignedPreKeyRecord signedPreKey;
  static late PreKeyBundle preKeyBundle;
  static late SignalProtocolAddress signalProtocolAddress;
  static late SessionBuilder sessionBuilder;

  EncryptedUser();

  static Future<void> initEncryptedUser(String? userId) async {
    identityKeyPair = generateIdentityKeyPair();
    registrationId = generateRegistrationId(false);
    identityKeyStore =
        InMemoryIdentityKeyStore(identityKeyPair, registrationId);

    String? deviceIdString = await _getDeviceId();
    deviceId = int.parse(deviceIdString!.replaceAll(RegExp(r'[^\d]'), ''));
    signalProtocolAddress = SignalProtocolAddress(userId!, deviceId);

    preKeyStore = InMemoryPreKeyStore();
    signedPreKeyStore = InMemorySignedPreKeyStore();
    sessionStore = InMemorySessionStore();
  }

  static Future<String?> _getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // Unique ID on iOS
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.id; // Unique ID on Android
    }
  }

  static createPreKeyBundle() {
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
