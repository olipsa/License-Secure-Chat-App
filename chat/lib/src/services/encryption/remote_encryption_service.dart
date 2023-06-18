import 'dart:typed_data';

import 'package:chat/chat.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

class RemoteEncryptionService implements IRemoteEncryptionService {
  final Connection _connection;
  final RethinkDb _r;
  RemoteEncryptionService(this._r, this._connection);

  @override
  Future<void> storePreKeyBundle(
      String? userId, PreKeyBundle preKeyBundle) async {
    await _r.table('public_keys').insert({
      'user_id': userId,
      'registrationId': preKeyBundle.getRegistrationId(),
      'deviceId': preKeyBundle.getDeviceId(),
      'preKeyId': preKeyBundle.getPreKeyId(),
      'preKeyPublic': preKeyBundle.getPreKey()!.serialize(),
      'signedPreKeyId': preKeyBundle.getSignedPreKeyId(),
      'signedPreKeyPublic': preKeyBundle.getSignedPreKey()!.serialize(),
      'signedPreKeySignature': preKeyBundle.getSignedPreKeySignature(),
      'identityKey': preKeyBundle.getIdentityKey().serialize()
    }, {
      'conflict': 'update',
    }).run(_connection);
  }

  @override
  Future<PreKeyBundle> retrievePreKeyBundle(String? userId) async {
    final cursor = await _r
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

  @override
  Future<int> retrieveDeviceId(String userId) async {
    final cursor = await _r
        .table('public_keys')
        .filter({'user_id': userId}).run(_connection);
    var records = await cursor.toList();
    var foundKey = records[0];
    int deviceId = foundKey['deviceId'];
    return deviceId;
  }
}
