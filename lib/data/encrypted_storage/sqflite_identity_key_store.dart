// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class SqfliteIdentityKeyStore extends InMemoryIdentityKeyStore {
  final Database _db;

  SqfliteIdentityKeyStore._(identityKeyPair, registrationId, this._db)
      : super(identityKeyPair, registrationId);

  // Factory constructor
  static Future<SqfliteIdentityKeyStore> create(Database db) async {
    // Check if keys are in the database
    final userIdentityMap = await db.query('user_identity');
    if (userIdentityMap.isNotEmpty) {
      // Load keys from the database
      int registrationId = userIdentityMap.first['registration_id'] as int;
      Uint8List serializedIdentityKeyPair =
          userIdentityMap.first['identity_key_pair'] as Uint8List;
      IdentityKeyPair identityKeyPair =
          IdentityKeyPair.fromSerialized(serializedIdentityKeyPair);
      SqfliteIdentityKeyStore instance =
          SqfliteIdentityKeyStore._(identityKeyPair, registrationId, db);
      await instance._loadTrustedKeys();
      return instance;
    } else {
      // Generate new keys and store them in memory and db
      IdentityKeyPair identityKeyPair = generateIdentityKeyPair();
      int registrationId = generateRegistrationId(false);
      SqfliteIdentityKeyStore instance =
          SqfliteIdentityKeyStore._(identityKeyPair, registrationId, db);
      instance._storeKeys(identityKeyPair, registrationId);
      return instance;
    }
  }

  Future<void> _storeKeys(
      IdentityKeyPair identityKeyPair, int registrationId) async {
    var userIdentityMap = {
      'registration_id': registrationId,
      'identity_key_pair': identityKeyPair.serialize()
    };
    await _db.transaction((txn) async {
      await txn.insert('user_identity', userIdentityMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> _loadTrustedKeys() async {
    final trustedKeysMap = await _db.query('trusted_keys');
    for (var entry in trustedKeysMap) {
      String addressString = entry['address'] as String;
      Uint8List serializedIdentityKey = entry['identity_key'] as Uint8List;

      SignalProtocolAddress address = parseAddressString(addressString);
      IdentityKey identityKey = IdentityKey.fromBytes(serializedIdentityKey, 0);

      // Call the saveIdentity method of the superclass
      await super.saveIdentity(address, identityKey);
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
  Future<bool> saveIdentity(
      SignalProtocolAddress address, IdentityKey? identityKey) async {
    if (await super.saveIdentity(address, identityKey)) {
      // if it's a new identity
      var identityMap = {
        'address': address.toString(),
        'identity_key': identityKey!.serialize()
      };
      await _db.transaction((txn) async {
        await txn.insert('trusted_keys', identityMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      });
      return true;
    }
    return false;
  }
}
