// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:path_provider/path_provider.dart';

class EncryptedUserTest {
  late InMemoryIdentityKeyStore identityKeyStore;
  late InMemoryPreKeyStore preKeyStore;
  late InMemorySignedPreKeyStore signedPreKeyStore;
  late InMemorySessionStore sessionStore; // tbd
  late IdentityKeyPair identityKeyPair;
  late int registrationId;
  int deviceId = 1;

  EncryptedUserTest() {
    sessionStore = InMemorySessionStore();
    preKeyStore = InMemoryPreKeyStore();
    signedPreKeyStore = InMemorySignedPreKeyStore();
    // These preKeyBundles should be retrieved from the server
    identityKeyPair = generateIdentityKeyPair();
    registrationId = generateRegistrationId(false);
    identityKeyStore =
        InMemoryIdentityKeyStore(identityKeyPair, registrationId);
  }

  get getIdentityKeyStore => identityKeyStore;
  get getPreKeyStore => preKeyStore;
  get getSignedPreKeyStore => signedPreKeyStore;
  get getSessionStore => sessionStore;
  get getIdentityKeyPair => identityKeyPair;
  set setIdentityKeyPair(identityKeyPair) =>
      this.identityKeyPair = identityKeyPair;
  get getRegistrationId => registrationId;
  set setRegistrationId(registrationId) => this.registrationId = registrationId;
}

void main() async {
  // this is done initially
  EncryptedUserTest alice = EncryptedUserTest();

  final alicePreKeyBundle = generatePreKeyBundle(alice);

  EncryptedUserTest bob = EncryptedUserTest();
  final bobPreKeyBundle = generatePreKeyBundle(bob);

  const aliceAddress = SignalProtocolAddress('alice2', 1);
  const bobAddress = SignalProtocolAddress('bob2', 1);

  // this is done for the first message sent/received only
  var aliceSessionCipher = SessionCipher(alice.sessionStore, alice.preKeyStore,
      alice.signedPreKeyStore, alice.identityKeyStore, bobAddress);
  final aliceSessionBuilder = SessionBuilder(
      alice.sessionStore,
      alice.preKeyStore,
      alice.signedPreKeyStore,
      alice.identityKeyStore,
      bobAddress);

  if (!await alice.sessionStore.containsSession(bobAddress)) {
    await aliceSessionBuilder.processPreKeyBundle(bobPreKeyBundle);
    print("session created with Bob");
  } else {
    print("session already existing with Bob");
  }

  final bobSessionBuilder = SessionBuilder(bob.sessionStore, bob.preKeyStore,
      bob.signedPreKeyStore, bob.identityKeyStore, aliceAddress);
  if (!await bob.sessionStore.containsSession(aliceAddress)) {
    await bobSessionBuilder.processPreKeyBundle(alicePreKeyBundle);
    print("session created with Alice");
  } else {
    print("session already existing with Alice");
  }

  var bobSessionCipher = SessionCipher(bob.sessionStore, bob.preKeyStore,
      bob.signedPreKeyStore, bob.identityKeyStore, aliceAddress);

  Uint8List plaintext = Uint8List.fromList(utf8.encode('Hello, world!'));
  CiphertextMessage ciphertext = await aliceSessionCipher.encrypt(plaintext);

  Uint8List serializedCiphertext = ciphertext
      .serialize(); // store it to server until it is received, then delete it
  print(ciphertext.getType());

  Uint8List decryptedMessage;
  String storedInDb = base64Encode(serializedCiphertext);
  serializedCiphertext = base64Decode(storedInDb);

  // decrypt before key
  PreKeySignalMessage preKeySignalMessage =
      PreKeySignalMessage(serializedCiphertext);
  decryptedMessage = await bobSessionCipher.decrypt(preKeySignalMessage);
  print('before key: ${utf8.decode(decryptedMessage)}');

  // after key
  aliceSessionCipher = SessionCipher(alice.sessionStore, alice.preKeyStore,
      alice.signedPreKeyStore, alice.identityKeyStore, bobAddress);
  plaintext = Uint8List.fromList(utf8.encode('Hello, world2!'));
  ciphertext = await aliceSessionCipher.encrypt(plaintext);
  print(ciphertext.getType());

  serializedCiphertext = ciphertext.serialize();

  bobSessionCipher = SessionCipher(bob.sessionStore, bob.preKeyStore,
      bob.signedPreKeyStore, bob.identityKeyStore, aliceAddress);
  preKeySignalMessage = PreKeySignalMessage(serializedCiphertext);
  decryptedMessage = await bobSessionCipher.decrypt(preKeySignalMessage);
  print('after key: ${utf8.decode(decryptedMessage)}');

  // create new user to connect with Alice

  EncryptedUserTest john = EncryptedUserTest();

  final johnPreKeyBundle = generatePreKeyBundle(john);

  const johnAddress = SignalProtocolAddress('john', 1);

  final johnSessionBuilder = SessionBuilder(john.sessionStore, john.preKeyStore,
      john.signedPreKeyStore, john.identityKeyStore, aliceAddress);
  if (!await john.sessionStore.containsSession(aliceAddress)) {
    await johnSessionBuilder.processPreKeyBundle(alicePreKeyBundle);
    print("session created with Alice");
  } else {
    print("session already existing with Alice");
  }

  plaintext = Uint8List.fromList(utf8.encode('Hello from John to Alice'));
  var johnSessionCipher = SessionCipher(john.sessionStore, john.preKeyStore,
      john.signedPreKeyStore, john.identityKeyStore, aliceAddress);
  ciphertext = await johnSessionCipher.encrypt(plaintext);

  serializedCiphertext = ciphertext
      .serialize(); // store it to server until it is received, then delete it
  print(ciphertext.getType());

  // decrypt by alice
  // if (!await alice.sessionStore.containsSession(johnAddress)) {
  //   await aliceSessionBuilder.processPreKeyBundle(johnPreKeyBundle);
  //   print("session created with John");
  // } else {
  //   print("session already existing with John");
  // }
  aliceSessionCipher = SessionCipher(alice.sessionStore, alice.preKeyStore,
      alice.signedPreKeyStore, alice.identityKeyStore, johnAddress);
  preKeySignalMessage = PreKeySignalMessage(serializedCiphertext);
  decryptedMessage = await aliceSessionCipher.decrypt(preKeySignalMessage);
  print('after key: ${utf8.decode(decryptedMessage)}');

  // final SignalMessage deserializedCiphertext =
  //     SignalMessage.fromSerialized(serializedCiphertext);
  // decryptedMessage =
  //     await bobSessionCipher.decryptFromSignal(deserializedCiphertext);

  // send encrypted images
  // WidgetsFlutterBinding.ensureInitialized();
  // final directory = await getApplicationDocumentsDirectory();
  // var path = directory.path;
  // final imageBytes =
  //     await File('$path/scaled_a789d299452f731b35b55f4f054bfafc.jpg')
  //         .readAsBytes();
  // print(imageBytes.toString());
  // ciphertext = await aliceSessionCipher.encrypt(Uint8List.fromList(imageBytes));
  // print(ciphertext.getType());

  // serializedCiphertext = ciphertext
  //     .serialize(); // store it to server until it is received, then delete it
  // contentType = ciphertext.getType();
  // print(contentType);

  // PreKeySignalMessage preKeySignalMessage =
  //     PreKeySignalMessage(serializedCiphertext);
  // decryptedMessage = await bobSessionCipher.decrypt(preKeySignalMessage);
  // final decryptedImgPath = '$path/decrypted_image.jpg';
  // await File(decryptedImgPath).writeAsBytes(decryptedMessage);
  // print('done');

  // ciphertext = await aliceSessionCipher.encrypt(Uint8List.fromList(imageBytes));
  // print(ciphertext.getType());
  // preKeySignalMessage = PreKeySignalMessage(serializedCiphertext);
}

PreKeyBundle generatePreKeyBundle(EncryptedUserTest user) {
  const preKeyId = 0;

  // one-time pre-keys -> OTPKs
  final List<PreKeyRecord> preKeys = generatePreKeys(preKeyId, 110);

  // Find the pre-key with the matching ID from the preKeys list
  late PreKeyRecord matchingPreKey;
  int count = 0;
  // print(preKeys.length);
  for (PreKeyRecord preKey in preKeys) {
    if (preKey.id == preKeyId) {
      matchingPreKey = preKey;
    }
  }

  for (PreKeyRecord preKey in preKeys) {
    user.preKeyStore.storePreKey(preKey.id, preKey);
  }
  // print(count);

  int signedPreKeyId = 0;
  SignedPreKeyRecord signedPreKey =
      generateSignedPreKey(user.identityKeyPair, signedPreKeyId);
  user.signedPreKeyStore.storeSignedPreKey(signedPreKeyId, signedPreKey);
  // print(matchingPreKey.getKeyPair().publicKey);

  return PreKeyBundle(
    user.registrationId,
    user.deviceId,
    preKeyId,
    matchingPreKey.getKeyPair().publicKey,
    signedPreKeyId,
    signedPreKey.getKeyPair().publicKey,
    signedPreKey.signature,
    user.identityKeyPair.getPublicKey(),
  );
}

Future<PreKeyBundle> getPreKeyBundle(EncryptedUserTest user) async {
  int preKeyId = 1;
  var preKey = await user.preKeyStore.loadPreKey(preKeyId);
  int signedPreKeyId = 0;
  var signedPreKey =
      await user.signedPreKeyStore.loadSignedPreKey(signedPreKeyId);
  return PreKeyBundle(
    user.registrationId,
    user.deviceId,
    preKeyId,
    preKey.getKeyPair().publicKey,
    signedPreKeyId,
    signedPreKey.getKeyPair().publicKey,
    signedPreKey.signature,
    user.identityKeyPair.getPublicKey(),
  );
}
