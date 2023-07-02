// ignore_for_file: public_member_api_docs, sort_constructors_first, avoid_print
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
    // create the session builder
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

  _replaceOneTimePreKey(String myUserId) async {
    int currentId = _user.preKeyId;
    // remove preKey from local storage
    _user.preKeyStore.removePreKey(currentId);
    int newpreKeyId = currentId + 1;
    _user.preKeyId = newpreKeyId;
    var nextPreKey = await _user.preKeyStore.loadPreKey(newpreKeyId);
    // update current preKeyId in local storage
    await _user.preKeyStore.updateCurrentPreKey(newpreKeyId);
    // update PreKeyBundle in Rethink DB with next prekey
    await _remoteEncryptionService.updateOneTimePreKey(
        myUserId, nextPreKey.getKeyPair().publicKey, newpreKeyId);
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
    var contents = message.contents['text'];
    final Uint8List plaintext = Uint8List.fromList(utf8.encode(contents));
    CiphertextMessage ciphertext = await cipher.encrypt(plaintext);
    Uint8List serializedCiphertext = ciphertext.serialize();
    var encryptedContent = {
      "encrypted_content": base64Encode(serializedCiphertext)
    };
    var signalType = ciphertext.getType();
    return Message(
        from: message.from,
        to: message.to,
        timestamp: message.timestamp,
        contents: encryptedContent,
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
    Uint8List descriptionBytes =
        Uint8List.fromList(utf8.encode(message.contents['text']));
    Uint8List fileBytes = message.contents['file'];

    Uint8List combinedBytes;
    Uint8List descriptionLengthBytes = Uint8List(4);

    if (descriptionBytes.isEmpty) {
      combinedBytes =
          Uint8List(descriptionLengthBytes.length + fileBytes.length);
      combinedBytes.setRange(
          descriptionLengthBytes.length, combinedBytes.length, fileBytes);
    } else {
      // concatenate both the file and it's description in a byte array to encrypt it
      // description byte array length also needst to be concatenated to be able to decrypt
      ByteData.view(descriptionLengthBytes.buffer)
          .setInt32(0, descriptionBytes.length);
      combinedBytes = Uint8List(descriptionLengthBytes.length +
          descriptionBytes.length +
          fileBytes.length);

      combinedBytes.setRange(
          0, descriptionLengthBytes.length, descriptionLengthBytes);
      combinedBytes.setRange(
          descriptionLengthBytes.length,
          descriptionLengthBytes.length + descriptionBytes.length,
          descriptionBytes);
      combinedBytes.setRange(
          descriptionLengthBytes.length + descriptionBytes.length,
          combinedBytes.length,
          fileBytes);
    }

    CiphertextMessage ciphertext = await cipher.encrypt(combinedBytes);
    Uint8List serializedCiphertext = ciphertext.serialize();
    var signalType = ciphertext.getType();
    var fileEncryptedContent = {
      "encrypted_content": base64Encode(serializedCiphertext)
    };
    return Message(
        from: message.from,
        to: message.to,
        timestamp: message.timestamp,
        contents: fileEncryptedContent,
        signalType: signalType,
        contentType: message.contentType,
        filePath: message.filePath);
  }

  Future<Message> encryptMessage(Message message) async {
    if (message.contentType == ContentType.text) {
      // for text messages
      return await encryptMessageText(message);
    } else if (message.contentType == ContentType.image ||
        message.contentType == ContentType.video ||
        message.contentType == ContentType.voice) {
      // for image files
      return await encryptMessageFile(message);
    }
    return await encryptMessageText(message);
  }

  Future<Message> decryptMessageText(Message message) async {
    String? recipientId = message.from;
    String? myId = message.to;
    String contents = message.contents['encrypted_content'];
    var signalType = message.signalType;

    SignalProtocolAddress recipientAddress = SignalProtocolAddress(
        recipientId!, await _retrieveDeviceId(recipientId));

    bool replacePreKey = false;
    if (!await _user.sessionStore.containsSession(recipientAddress)) {
      //message encrypted with a session that was not established previously
      await createSecureSession(recipientId, recipientAddress);
      replacePreKey = true;
    }

    // decrypt message
    final Uint8List serializedCiphertext = base64Decode(contents);
    SessionCipher cipher = createSessionCipher(recipientAddress);
    Uint8List decryptedMessage;
    if (signalType == CiphertextMessage.prekeyType) {
      PreKeySignalMessage preKeySignalMessage =
          PreKeySignalMessage(serializedCiphertext);
      decryptedMessage = await cipher.decrypt(preKeySignalMessage);
    } else if (signalType == CiphertextMessage.whisperType) {
      SignalMessage signalMessage =
          SignalMessage.fromSerialized(serializedCiphertext);
      decryptedMessage = await cipher.decryptFromSignal(signalMessage);
    } else {
      decryptedMessage = base64Decode('');
    }

    if (replacePreKey) {
      // remove one-time pre key from the server
      _replaceOneTimePreKey(myId!);
    }
    message.contents = {'text': utf8.decode(decryptedMessage)};
    return message;
  }

  Future<Message> decryptMessageFile(Message message) async {
    String? recipientId = message.from;
    String? myId = message.to;
    String fileContents = message.contents['encrypted_content'];
    var signalType = message.signalType;

    SignalProtocolAddress recipientAddress = SignalProtocolAddress(
        recipientId!, await _retrieveDeviceId(recipientId));

    bool replacePreKey = false;
    if (!await _user.sessionStore.containsSession(recipientAddress)) {
      //message encrypted with a session that was not established previously
      await createSecureSession(recipientId, recipientAddress);
      replacePreKey = true;
    }

    // decrypt message
    SessionCipher cipher = createSessionCipher(recipientAddress);
    final Uint8List serializedCiphertext = base64Decode(fileContents);
    Uint8List decryptedFileContents;

    if (signalType == CiphertextMessage.whisperType) {
      // message encrypted with an established session
      final SignalMessage signalMessage =
          SignalMessage.fromSerialized(serializedCiphertext);
      decryptedFileContents = await cipher.decryptFromSignal(signalMessage);
    } else if (signalType == CiphertextMessage.prekeyType) {
      //message encrypted with a session that was not established previously
      PreKeySignalMessage preKeySignalMessage =
          PreKeySignalMessage(serializedCiphertext);
      decryptedFileContents = await cipher.decrypt(preKeySignalMessage);
    } else {
      decryptedFileContents = base64Decode('');
    }
    if (replacePreKey) {
      // remove one-time pre key from the server
      _replaceOneTimePreKey(myId!);
    }

    Uint8List decryptedDescriptionLengthBytes =
        decryptedFileContents.sublist(0, 4);
    int descriptionLength =
        ByteData.view(decryptedDescriptionLengthBytes.buffer).getInt32(0);

    Uint8List decryptedDescriptionBytes =
        decryptedFileContents.sublist(4, 4 + descriptionLength);
    Uint8List decryptedFileBytes =
        decryptedFileContents.sublist(4 + descriptionLength);

    message.filePath = await _storeDecryptedFile(
        decryptedFileBytes, message.contentType, message.timestamp);
    message.contents['text'] = utf8.decode(decryptedDescriptionBytes);

    return message;
  }

  Future<Message> decryptMessage(Message message) async {
    if (message.contentType == ContentType.text) {
      // for text messages
      return await decryptMessageText(message);
    } else if (message.contentType == ContentType.image ||
        message.contentType == ContentType.video ||
        message.contentType == ContentType.voice) {
      // for image files; decrypt the file and it's description if it exists
      return await decryptMessageFile(message);
    }
    return decryptMessageText(message);
  }

  Future<String> _storeDecryptedFile(Uint8List decryptedFile,
      ContentType contentType, DateTime timestamp) async {
    String decryptedFileType = '';
    String extension = '';
    switch (contentType) {
      case ContentType.image:
        decryptedFileType = 'IMG';
        extension = 'jpg';
        break;
      case ContentType.video:
        decryptedFileType = 'VID';
        extension = 'mp4';
        break;
      case ContentType.voice:
        decryptedFileType = 'AUDIO';
        extension = 'aac';
        break;
      default:
    }
    final directory = await getExternalStorageDirectory();
    print(directory);
    List<FileSystemEntity> files = directory!.listSync();
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
      decryptedFilePath = '${directory.path}/$newFileName.$extension';
    } else {
      // no other files sent at this date
      decryptedFilePath = '${directory.path}/$prefixTypeDate-0000.$extension';
    }
    final newFile = await File(decryptedFilePath).writeAsBytes(decryptedFile);
    print("New file created: ${newFile.path}");
    return newFile.path;
  }

  Future<int> _retrieveDeviceId(String userId) async {
    return await _remoteEncryptionService.retrieveDeviceId(userId);
  }
}
