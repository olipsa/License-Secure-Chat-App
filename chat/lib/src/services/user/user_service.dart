// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:chat/src/services/user/user_service_contract.dart';
import 'package:chat/src/models/user.dart';
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
  Future<List<User>> contacts(Map<String, String> phoneDisplayNameMap) async {
    List<dynamic> userList = [];
    try {
      // filter users that have a phone number
      Cursor users = await r.table('users').run(_connection!);

      userList = await users.toList();
      await users.close();
    } catch (e, stackTrace) {
      print('Error: $e');
      print('StackTrace: $stackTrace');
    }

    print("in rethink db");
    print(userList.toString());
    print("\n in contacts");
    print(phoneDisplayNameMap.keys.toString());

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
