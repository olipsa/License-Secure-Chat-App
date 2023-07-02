import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class SqflitePreKeyKeyStore extends InMemoryPreKeyStore {
  final Database _db;
  SqflitePreKeyKeyStore(this._db) : super();

  static Future<SqflitePreKeyKeyStore> create(Database db) async {
    // Check if keys are in the database
    final preKeyMap = await db.query('pre_keys');
    if (preKeyMap.isNotEmpty) {
      // Load pre keys from the database and store them in memory
      SqflitePreKeyKeyStore instance = SqflitePreKeyKeyStore(db);
      int preKeyId;
      Uint8List serializedPreKey;
      PreKeyRecord preKeyRecord;
      for (var preKey in preKeyMap) {
        preKeyId = preKey['id'] as int;
        serializedPreKey = preKey['pre_key'] as Uint8List;
        preKeyRecord =
            PreKeyRecord.fromBuffer(serializedPreKey); // or from serialized
        instance.store[preKeyId] = preKeyRecord.serialize();
      }
      return instance;
    } else {
      // Generate new keys and store them in memory & db
      var preKeys = generatePreKeys(0, 110);
      SqflitePreKeyKeyStore instance = SqflitePreKeyKeyStore(db);
      for (PreKeyRecord preKey in preKeys) {
        instance.storePreKey(preKey.id, preKey);
      }
      return instance;
    }
  }

  @override
  Future<void> storePreKey(int preKeyId, PreKeyRecord record) async {
    store[preKeyId] = record.serialize();
    var preKeyMap = {'id': preKeyId, 'pre_key': record.serialize()};

    await _db.transaction((txn) async {
      await txn.insert('pre_keys', preKeyMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> removePreKey(int preKeyId) async {
    store.remove(preKeyId);
    final batch = _db.batch();
    batch.delete('pre_keys', where: 'id = ?', whereArgs: [preKeyId]);
    batch.delete('metadata',
        where: 'current_pre_key_id = ?', whereArgs: [preKeyId]);
    await batch.commit(noResult: true);
  }

  Future<void> updateCurrentPreKey(int preKeyId) async {
    await _db.insert('metadata', {'current_pre_key_id': preKeyId});
  }

  Future<int> getCurrentPreKeyId() async {
    final result =
        await _db.query('metadata', columns: ['current_pre_key_id'], limit: 1);
    if (result.isNotEmpty) {
      return result.first['current_pre_key_id'] as int;
    } else {
      initializePreKeyId();
      return 0;
    }
  }

  Future<void> initializePreKeyId() async {
    await _db.insert('metadata', {'current_pre_key_id': 0});
  }
}
