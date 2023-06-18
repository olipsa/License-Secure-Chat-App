// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:chat/chat.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/models/encrypted_user.dart';
import 'package:intl/intl.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<Message> encryptMessageText(Message message) async {
    String? recipientId = message.to;
    SignalProtocolAddress recipientAddress = SignalProtocolAddress(
        recipientId!, await _retrieveDeviceId(recipientId));
    if (!await _user.sessionStore.containsSession(recipientAddress)) {
      await createSecureSession(recipientId, recipientAddress);
    }
    SessionCipher cipher = createSessionCipher(recipientAddress);
    var contents = message.contents;
    final Uint8List plaintext = Uint8List.fromList(utf8.encode(contents));
    CiphertextMessage ciphertext = await cipher.encrypt(plaintext);
    var messageContent = base64Encode(ciphertext.serialize());
    var signalType = ciphertext.getType();
    return Message(
        from: message.from,
        to: message.to,
        timestamp: message.timestamp,
        contents: messageContent,
        signalType: signalType,
        contentType: message.contentType);
  }

  Future<Message> encryptMessageFile(Message message) async {
    String? recipientId = message.to;
    SignalProtocolAddress recipientAddress = SignalProtocolAddress(
        recipientId!, await _retrieveDeviceId(recipientId));
    if (!await _user.sessionStore.containsSession(recipientAddress)) {
      await createSecureSession(recipientId, recipientAddress);
    }
    SessionCipher cipher = createSessionCipher(recipientAddress);
    final imageBytes = await File(message.filePath!).readAsBytes();
    CiphertextMessage ciphertext =
        await cipher.encrypt(Uint8List.fromList(imageBytes));
    var imageEncryptedContentString = base64Encode(ciphertext.serialize());
    var signalType = ciphertext.getType();
    return Message(
        from: message.from,
        to: message.to,
        timestamp: message.timestamp,
        contents: message.contents,
        signalType: signalType,
        contentType: message.contentType,
        filePath: message.filePath,
        fileContents: imageEncryptedContentString);
  }

  Future<Message> encryptMessage(Message message) async {
    if (message.contentType == ContentType.text) {
      // for text messages
      return await encryptMessageText(message);
    } else if (message.contentType == ContentType.image) {
      // for image files
      Message encryptedImageContent = await encryptMessageFile(message);
      if (message.contents.isNotEmpty) {
        Message encryptedImageDescription = await encryptMessageText(message);
        encryptedImageContent.contents = encryptedImageDescription.contents;
      }
      return encryptedImageContent;
    }
    return await encryptMessageText(message);
  }

  Future<Message> decryptMessageText(Message message) async {
    String? recipientId = message.from;
    SignalProtocolAddress recipientAddress = SignalProtocolAddress(
        recipientId!, await _retrieveDeviceId(recipientId));
    if (!await _user.sessionStore.containsSession(recipientAddress)) {
      createSecureSession(recipientId, recipientAddress);
    }
    SessionCipher cipher = createSessionCipher(recipientAddress);

    var contents = message.contents;
    final Uint8List serializedCiphertext =
        Uint8List.fromList(base64Decode(contents));
    late Uint8List decryptedMessage;

    try {
      if (message.signalType == CiphertextMessage.whisperType) {
        // message encrypted with an established session
        final SignalMessage deserializedCiphertext =
            SignalMessage.fromSerialized(serializedCiphertext);
        decryptedMessage =
            await cipher.decryptFromSignal(deserializedCiphertext);
      } else if (message.signalType == CiphertextMessage.prekeyType) {
        //message encrypted with a session that was not established previously
        PreKeySignalMessage preKeySignalMessage =
            PreKeySignalMessage(serializedCiphertext);
        decryptedMessage = await cipher.decrypt(preKeySignalMessage);
      } else {
        print("Invalid CiphertextMessage object.");
        print('Type of ciphertext is ');
        print(message.signalType);
      }
    } on UntrustedIdentityException catch (e) {
      // Handle the UntrustedIdentityException, e.g., by prompting the user to accept the new identity key
      print(
          "Sender's identity key has changed. Please verify and accept the new identity key.\n$e");
    }
    message.contents = utf8.decode(decryptedMessage);
    return message;
  }

  Future<Message> decryptMessageFile(Message message) async {
    String? recipientId = message.from;
    SignalProtocolAddress recipientAddress = SignalProtocolAddress(
        recipientId!, await _retrieveDeviceId(recipientId));
    if (!await _user.sessionStore.containsSession(recipientAddress)) {
      createSecureSession(recipientId, recipientAddress);
    }
    SessionCipher cipher = createSessionCipher(recipientAddress);
    final Uint8List serializedCiphertext =
        Uint8List.fromList(base64Decode(message.fileContents!));
    late Uint8List decryptedFile;

    try {
      if (message.signalType == CiphertextMessage.whisperType) {
        // message encrypted with an established session
        final SignalMessage deserializedCiphertext =
            SignalMessage.fromSerialized(serializedCiphertext);
        decryptedFile = await cipher.decryptFromSignal(deserializedCiphertext);
      } else if (message.signalType == CiphertextMessage.prekeyType) {
        //message encrypted with a session that was not established previously
        PreKeySignalMessage preKeySignalMessage =
            PreKeySignalMessage(serializedCiphertext);
        decryptedFile = await cipher.decrypt(preKeySignalMessage);
      } else {
        print("Invalid CiphertextMessage object.");
        print('Type of ciphertext is ');
        print(message.signalType);
      }
    } on UntrustedIdentityException catch (e) {
      // Handle the UntrustedIdentityException, e.g., by prompting the user to accept the new identity key
      print(
          "Sender's identity key has changed. Please verify and accept the new identity key.\n$e");
    }
    message.filePath = await _storeDecryptedFile(
        decryptedFile, message.contentType, message.timestamp);

    return message;
  }

  Future<String> _storeDecryptedFile(Uint8List decryptedFile,
      ContentType contentType, DateTime timestamp) async {
    String decryptedFileType = '';
    switch (contentType) {
      case ContentType.image:
        decryptedFileType = 'IMG';
        break;
      case ContentType.video:
        decryptedFileType = 'VID';
        break;
      default:
    }
    final directory = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> files = directory.listSync();
    var dateFormat = DateFormat('yyyyMMdd').format(timestamp);
    var prefixTypeDate = '$decryptedFileType-$dateFormat';
    List<File> filesWithPrefix = files
        .where((file) =>
            file is File &&
            file.path.split('/').last.startsWith(prefixTypeDate))
        .cast<File>()
        .toList();
    String decryptedFilePath = '';
    if (filesWithPrefix.isNotEmpty) {
      filesWithPrefix.sort((a, b) => a.path.compareTo(b.path));
      File lastFile = filesWithPrefix.last;

      // exract the number from the last file
      RegExp numberPattern = RegExp(r'(\d+)(?=\.[^.]+$)');
      var numberMatch = numberPattern.firstMatch(lastFile.path.split('/').last);
      int currentNumber = int.parse(numberMatch!.group(0)!);

      // increment the number and create a new file
      int nextNumber = currentNumber + 1;
      String nextNumberString = nextNumber.toString().padLeft(4, '0');
      String newFileName = '$prefixTypeDate-$nextNumberString';
      decryptedFilePath = '${directory.path}/$newFileName.jpg';
    } else {
      // no other files sent at this date
      decryptedFilePath = '${directory.path}/$prefixTypeDate-0000.jpg';
    }
    final newFile = await File(decryptedFilePath).writeAsBytes(decryptedFile);
    print("New file created: ${newFile.path}");
    return newFile.path;
  }

  Future<Message> decryptMessage(Message message) async {
    if (message.contentType == ContentType.text) {
      // for text messages
      return await decryptMessageText(message);
    } else if (message.contentType == ContentType.image) {
      // for image files; decrypt the file and it's description if it exists
      Message decryptedImageContent = await decryptMessageFile(message);
      if (message.contents.isNotEmpty) {
        Message encryptedImageDescription = await decryptMessageText(message);
        decryptedImageContent.contents = encryptedImageDescription.contents;
      }
      return decryptedImageContent;
    }
    return decryptMessageText(message);
  }

  Future<int> _retrieveDeviceId(String userId) async {
    return await _remoteEncryptionService.retrieveDeviceId(userId);
  }
}
