// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:chat/src/services/user/user_service_contract.dart';
import 'package:chat/src/models/user.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';
import 'package:crypto/crypto.dart';

class UserService implements IUserService {
  final Connection? _connection;
  final RethinkDb r;

  UserService({
    required this.r,
    required Connection? connection,
  }) : _connection = connection;

  @override
  Future<User> connect(User user) async {
    String hashedPassphrase = _hashPassphrase(user.passphrase!);
    User userInserted = User(
        username: user.username,
        photoUrl: user.photoUrl,
        active: user.active,
        lastseen: user.lastseen,
        phoneNumber: user.phoneNumber,
        passphrase: hashedPassphrase);
    userInserted.id = user.id;

    var data = userInserted.toJson();

    if (user.id != null) data['id'] = user.id;

    final result = await r.table('users').insert(data, {
      'conflict': 'update',
      'return_changes': true //if it's a not already existing user
    }).run(_connection!);
    var userResult = result['changes'].first['new_val'];
    userResult['passphrase'] = user.passphrase;

    return User.fromJson(userResult);
  }

  String _hashPassphrase(String passphrase) {
    List<int> bytes = utf8.encode(passphrase);
    Digest digest = sha256.convert(bytes);
    return digest.toString(); // hashed passphrase
  }

  @override
  Future<void> disconnect(User user) async {
    await r.table('users').update({
      'id': user.id,
      'active': false,
      'lastseen': DateTime.now()
    }).run(_connection!);
    _connection?.close();
  }

  @override
  Future<List<User>> contacts(Map<String, String> phoneDisplayNameMap) async {
    List<dynamic> userList = [];
    try {
      // filter users that have a phone number
      Cursor users = await r.table('users').run(_connection!);
      userList = await users.toList();
    } catch (e, stackTrace) {
      print('Error: $e');
      print('StackTrace: $stackTrace');
    }

    // Update the userList with the display name from the contact display name
    List<User> existingUsers = userList
        .where((item) {
          String? phoneNumber = item['phone_number'];
          item['username'] = phoneDisplayNameMap[phoneNumber];
          return phoneNumber != null &&
              phoneDisplayNameMap.containsKey(phoneNumber);
        })
        .map((item) => User.fromJson(item))
        .toList();
    return existingUsers;
  }

  @override
  Future<User?> fetch(String? id) async {
    final user = await r.table('users').get(id).run(_connection!);
    if (user != null) {
      return User.fromJson(user);
    }
    return null;
  }

  @override
  Future<void> update(User user) async {
    await r.table('users').update({
      'id': user.id,
      'active': user.active,
      'lastseen': user.lastseen,
      'username': user.username
    }).run(_connection!);
  }
}
