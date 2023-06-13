// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:chat/src/services/user/user_service_contract.dart';
import 'package:chat/src/models/user.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

class UserService implements IUserService {
  final Connection? _connection;
  final RethinkDb r;

  UserService({
    required this.r,
    required Connection? connection,
  }) : _connection = connection;

  @override
  Future<User> connect(User user) async {
    var data = user.toJson();
    if (user.id != null) data['id'] = user.id;

    final result = await r.table('users').insert(data, {
      'conflict': 'update',
      'return_changes': true //if it's a not already existing user
    }).run(_connection!);

    return User.fromJson(result['changes'].first['new_val']);
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
  Future<List<User>> online() async {
    Cursor users =
        await r.table('users').filter({'active': true}).run(_connection!);
    final userList = await users.toList();
    return userList.map((item) => User.fromJson(item)).toList();
  }

  @override
  Future<User> fetch(String? id) async {
    final user = await r.table('users').get(id).run(_connection!);
    return User.fromJson(user);
  }

  @override
  Future<void> update(User user) async {
    await r.table('users').update({
      'id': user.id,
      'active': user.active,
      'lastseen': user.lastseen
    }).run(_connection!);
  }
}
