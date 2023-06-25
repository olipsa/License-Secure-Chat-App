// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteSignedPreKeyStore extends InMemorySignedPreKeyStore {
  final Database _db;
  SqfliteSignedPreKeyStore(this._db) : super();

  static Future<SqfliteSignedPreKeyStore> create(
      Database db, IdentityKeyPair identityKeyPair) async {
    // Check if keys are in the database
    final signedPreKeyMap = await db.query('signed_pre_keys');
    if (signedPreKeyMap.isNotEmpty) {
      // Load pre keys from the database and store them in memory
      SqfliteSignedPreKeyStore instance = SqfliteSignedPreKeyStore(db);
      int signedPreKeyId;
      Uint8List serializedSignedPreKey;
      SignedPreKeyRecord signedPreKeyRecord;
      for (var signedPreKey in signedPreKeyMap) {
        signedPreKeyId = signedPreKey['id'] as int;
        serializedSignedPreKey = signedPreKey['signed_pre_key'] as Uint8List;
        signedPreKeyRecord =
            SignedPreKeyRecord.fromSerialized(serializedSignedPreKey);
        instance.store[signedPreKeyId] = signedPreKeyRecord.serialize();
      }
      return instance;
    } else {
      // Generate new keys and store them in memory & db
      int signedPreKeyId = 0;
      var signedPreKey = generateSignedPreKey(identityKeyPair, signedPreKeyId);
      SqfliteSignedPreKeyStore instance = SqfliteSignedPreKeyStore(db);
      instance.storeSignedPreKey(signedPreKeyId, signedPreKey);

      return instance;
    }
  }

  @override
  Future<void> storeSignedPreKey(
      int signedPreKeyId, SignedPreKeyRecord record) async {
    store[signedPreKeyId] = record.serialize();
    var signedPreKeyMap = {
      'id': signedPreKeyId,
      'signed_pre_key': record.serialize()
    };

    await _db.transaction((txn) async {
      await txn.insert('signed_pre_keys', signedPreKeyMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }
}
