import 'package:chat/src/services/user/user_service.dart';
import 'package:chat/src/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  Connection? connection;
  late UserService sut;

  setUp(() async {
    connection = await r.connect(host: "127.0.0.1", port: 28015);
    await createDb(r, connection!);
    sut = UserService(r: r, connection: connection);
  });

  tearDown(() async {
    //await cleanDb(r, connection!);
  });

  test('creates a new user in db', () async {
    final user = User(
        username: 'ondina',
        photoUrl: 'url',
        active: true,
        lastseen: DateTime.now());
    final userWithId = await sut.connect(user);
    expect(userWithId.id, isNotEmpty);
  });

  test('get online users', () async {
    final user = User(
        username: 'test',
        photoUrl: 'url',
        active: true,
        lastseen: DateTime.now());
    await sut.connect(user);
    final users = await sut.online();
    expect(users.length, 1);
  });
}
