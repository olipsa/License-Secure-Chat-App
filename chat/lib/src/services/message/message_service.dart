import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:chat/chat.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

class MessageService implements IMessageService {
  final Connection _connection;
  final RethinkDb r;
  final StreamController<Message> _controller =
      StreamController<Message>.broadcast();
  final IEncryption? _encryption;
  StreamSubscription? _changefeed;

  MessageService(this.r, this._connection, {IEncryption? encryption})
      : _encryption = encryption;

  @override
  dispose() {
    _changefeed?.cancel();
    _controller.close();
  }

  @override
  Stream<Message> messages({required User activeUser}) {
    _startReceivingMessages(activeUser);
    return _controller.stream;
  }

  @override
  Future<Message> send(Message message) async {
    var data = message.toJson();
    SignalProtocolAddress recipientAddress =
        SignalProtocolAddress(message.to!, _getDeviceId(message.to!));
    if (!await EncryptedUser.sessionStore.containsSession(recipientAddress)) {
      // session was not created yet
      print("session not created with this user");
      PreKeyBundle recipientPreKey = await retrievePreKeyBundle(message.to);
      EncryptedUser.sessionBuilder = SessionBuilder(
          EncryptedUser.sessionStore,
          EncryptedUser.preKeyStore,
          EncryptedUser.signedPreKeyStore,
          EncryptedUser.identityKeyStore,
          recipientAddress);

      await EncryptedUser.sessionBuilder.processPreKeyBundle(recipientPreKey);
    } else {
      print("session already existing");
    }

    SessionCipher sessionCipher = SessionCipher(
        EncryptedUser.sessionStore,
        EncryptedUser.preKeyStore,
        EncryptedUser.signedPreKeyStore,
        EncryptedUser.identityKeyStore,
        recipientAddress);
    final Uint8List plaintext =
        Uint8List.fromList(utf8.encode(message.contents));
    CiphertextMessage ciphertext = await sessionCipher.encrypt(plaintext);
    data['contents'] = base64Encode(ciphertext.serialize());
    data['message_type'] = ciphertext.getType();

    Map record = await r
        .table('messages')
        .insert(data, {'return_changes': true}).run(_connection);
    Message returnedMessage =
        Message.fromJson(record['changes'].first['new_val']);
    returnedMessage.contents = message.contents;
    return returnedMessage;
  }

  _startReceivingMessages(User user) {
    _changefeed = r
        .table('messages')
        .filter({'to': user.id})
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event
              .forEach((feedData) async {
                if (feedData['new_val'] == null) return; // no new messages

                final message = await _messageFromFeed(feedData);
                _controller.sink.add(
                    message); //message added to the stream so that client can receive it
                _removeDeliverredMessage(message);
              })
              .catchError((err) => print(err))
              .onError((error, stackTrace) => print(error));
        }); //will send all messages that were sent before subscribing
  }

  Future<Message> _messageFromFeed(feedData) async {
    var data = feedData['new_val'];
    var senderId = data['from'];
    final messageType = data['message_type'];

    SignalProtocolAddress senderAddress =
        SignalProtocolAddress(senderId, _getDeviceId(senderId));
    if (!await EncryptedUser.sessionStore.containsSession(senderAddress)) {
      // session was not created yet
      print("session not created with this user");
      EncryptedUser.sessionBuilder = SessionBuilder(
          EncryptedUser.sessionStore,
          EncryptedUser.preKeyStore,
          EncryptedUser.signedPreKeyStore,
          EncryptedUser.identityKeyStore,
          senderAddress);
      PreKeyBundle senderPreKey = await retrievePreKeyBundle(senderId);

      await EncryptedUser.sessionBuilder.processPreKeyBundle(senderPreKey);
    } else {
      print("session already existing");
    }
    SessionCipher sessionCipher = SessionCipher(
        EncryptedUser.sessionStore,
        EncryptedUser.preKeyStore,
        EncryptedUser.signedPreKeyStore,
        EncryptedUser.identityKeyStore,
        senderAddress);
    final Uint8List serializedCiphertext =
        Uint8List.fromList(base64Decode(data['contents']));
    late Uint8List decryptedMessage;

    try {
      if (messageType == CiphertextMessage.whisperType) {
        print('whisperType');
        final SignalMessage deserializedCiphertext =
            SignalMessage.fromSerialized(serializedCiphertext);
        decryptedMessage =
            await sessionCipher.decryptFromSignal(deserializedCiphertext);
      } else if (messageType == CiphertextMessage.prekeyType) {
        print('prekeyType');
        PreKeySignalMessage preKeySignalMessage =
            PreKeySignalMessage(serializedCiphertext);
        decryptedMessage = await sessionCipher.decrypt(preKeySignalMessage);
      } else {
        print("Invalid CiphertextMessage object.");
        print('Type of ciphertext is ');
        print(messageType);
      }
    } on UntrustedIdentityException catch (e) {
      // Handle the UntrustedIdentityException, e.g., by prompting the user to accept the new identity key
      print(
          "Sender's identity key has changed. Please verify and accept the new identity key.");
      // Update the trust store with the new recipient's identity key if the user accepts it
      // ...
    }

    data['contents'] = utf8.decode(decryptedMessage);
    data.remove('message_type');
    return Message.fromJson(data);
  }

  _removeDeliverredMessage(Message message) {
    r
        .table('messages')
        .get(message.id)
        .delete({'return_changes': false}).run(_connection);
  }

  @override
  Future<PreKeyBundle> retrievePreKeyBundle(String? userId) async {
    final cursor = await r
        .table('public_keys')
        .filter({'user_id': userId}).run(_connection);
    var records = await cursor.toList();
    var foundKey = records[0];

    int registrationId = foundKey['registrationId'];
    int deviceId = foundKey['deviceId'];
    int preKeyId = foundKey['preKeyId'];
    int signedPreKeyId = foundKey['signedPreKeyId'];

    ECPublicKey preKeyPublic = Curve.decodePoint(
        Uint8List.fromList(_getIntList(foundKey['preKeyPublic'])), 0);

    ECPublicKey signedPreKeyPublic = Curve.decodePoint(
        Uint8List.fromList(_getIntList(foundKey['signedPreKeyPublic'])), 0);

    Uint8List signedPreKeySignature =
        Uint8List.fromList(_getIntList(foundKey['signedPreKeySignature']));
    IdentityKey identityKey = IdentityKey.fromBytes(
        Uint8List.fromList(_getIntList(foundKey['identityKey'])), 0);

    return PreKeyBundle(registrationId, deviceId, preKeyId, preKeyPublic,
        signedPreKeyId, signedPreKeyPublic, signedPreKeySignature, identityKey);
  }

  List<int> _getIntList(List<dynamic> dbRecord) {
    List<int> keyList = dbRecord.map<int>((dynamic element) {
      return element as int;
    }).toList();
    return keyList;
  }

  int _getDeviceId(String userId) {
    // tbd: get device id from db
    return 1220922025;
  }
}
