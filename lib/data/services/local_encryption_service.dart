// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:chat/chat.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/models/encrypted_user.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class LocalEncryptionService {
  final EncryptedUser _user;
  late final IRemoteEncryptionService _remoteEncryptionService;

  LocalEncryptionService(this._remoteEncryptionService, this._user);

  createSecureSession(
      String? recipientId, SignalProtocolAddress recipientAddress) async {
    SessionBuilder sessionBuilder = SessionBuilder(
        _user.sessionStore,
        _user.preKeyStore,
        _user.signedPreKeyStore,
        _user.identityKeyStore,
        recipientAddress);
    // fetch the PreKeyBundle from Rethink DB
    PreKeyBundle recipientPreKeyBundle =
        await _remoteEncryptionService.retrievePreKeyBundle(recipientId);
    await sessionBuilder.processPreKeyBundle(recipientPreKeyBundle);
  }

  SessionCipher createSessionCipher(SignalProtocolAddress recipientAddress) {
    return SessionCipher(_user.sessionStore, _user.preKeyStore,
        _user.signedPreKeyStore, _user.identityKeyStore, recipientAddress);
  }

  Future<Message> encryptMessage(Message message) async {
    String? recipientId = message.to;
    SignalProtocolAddress recipientAddress =
        SignalProtocolAddress(recipientId!, _retrieveDeviceId(recipientId));
    if (!await _user.sessionStore.containsSession(recipientAddress)) {
      await createSecureSession(recipientId, recipientAddress);
    }
    SessionCipher cipher = createSessionCipher(recipientAddress);
    final Uint8List plaintext =
        Uint8List.fromList(utf8.encode(message.contents));
    CiphertextMessage ciphertext = await cipher.encrypt(plaintext);
    var messageContent = base64Encode(ciphertext.serialize());
    var messageType = ciphertext.getType();
    return Message(
        from: message.from,
        to: message.to,
        timestamp: message.timestamp,
        contents: messageContent,
        type: messageType);
  }

  Future<Message> decryptMessage(Message message) async {
    String? recipientId = message.from;
    SignalProtocolAddress recipientAddress =
        SignalProtocolAddress(recipientId!, _retrieveDeviceId(recipientId));
    if (!await _user.sessionStore.containsSession(recipientAddress)) {
      createSecureSession(recipientId, recipientAddress);
    }
    SessionCipher cipher = createSessionCipher(recipientAddress);

    final Uint8List serializedCiphertext =
        Uint8List.fromList(base64Decode(message.contents));
    late Uint8List decryptedMessage;

    try {
      if (message.type == CiphertextMessage.whisperType) {
        print('whisperType');
        final SignalMessage deserializedCiphertext =
            SignalMessage.fromSerialized(serializedCiphertext);
        decryptedMessage =
            await cipher.decryptFromSignal(deserializedCiphertext);
      } else if (message.type == CiphertextMessage.prekeyType) {
        print('prekeyType');
        PreKeySignalMessage preKeySignalMessage =
            PreKeySignalMessage(serializedCiphertext);
        decryptedMessage = await cipher.decrypt(preKeySignalMessage);
      } else {
        print("Invalid CiphertextMessage object.");
        print('Type of ciphertext is ');
        print(message.type);
      }
    } on UntrustedIdentityException catch (e) {
      // Handle the UntrustedIdentityException, e.g., by prompting the user to accept the new identity key
      print(
          "Sender's identity key has changed. Please verify and accept the new identity key.");
    }
    message.contents = utf8.decode(decryptedMessage);
    return message;
  }

  int _retrieveDeviceId(String userId) {
    // tbd: get device id from db
    return 1220922025;
  }
}
