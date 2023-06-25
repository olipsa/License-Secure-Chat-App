import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteSessionStore extends InMemorySessionStore {
  final Database _db;
  SqfliteSessionStore(this._db) : super();

  static Future<SqfliteSessionStore> create(Database db) async {
    // Check if keys are in the database
    final sessionsMap = await db.query('sessions');
    if (sessionsMap.isNotEmpty) {
      SqfliteSessionStore instance = SqfliteSessionStore(db);
      // Load sessions from the database and store them in memory
      for (var entry in sessionsMap) {
        String addressString = entry['address'] as String;
        Uint8List serializedSession = entry['session'] as Uint8List;
        SignalProtocolAddress address =
            instance.parseAddressString(addressString);
        SessionRecord session = SessionRecord.fromSerialized(serializedSession);
        await instance.storeSession(address, session);
      }
      return instance;
    } else {
      SqfliteSessionStore instance = SqfliteSessionStore(db);
      return instance;
    }
  }

  SignalProtocolAddress parseAddressString(String addressString) {
    final parts = addressString.split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid address string format');
    }
    final name = parts[0];
    final deviceId = int.parse(parts[1]);
    return SignalProtocolAddress(name, deviceId);
  }

  @override
  Future<void> storeSession(
      SignalProtocolAddress address, SessionRecord record) async {
    sessions[address] = record.serialize();
    var sessionMap = {
      'address': address.toString(),
      'session': record.serialize()
    };
    await _db.transaction((txn) async {
      await txn.insert('sessions', sessionMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> deleteAllSessions(String name) async {
    for (final k in sessions.keys.toList()) {
      if (k.getName() == name) {
        sessions.remove(k);
      }
    }
    await _db.delete('sessions');
  }

  @override
  Future<void> deleteSession(SignalProtocolAddress address) async {
    sessions.remove(address);
    await _db.delete('sessions',
        where: 'address = ?', whereArgs: [address.toString()]);
  }
}
