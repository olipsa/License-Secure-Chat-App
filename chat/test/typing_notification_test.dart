import 'package:chat/src/models/typing_event.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/typing/typing_notification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  Connection? connection;
  TypingNotification? sut; //system under test

  setUp(() async {
    connection = await r.connect();
    await createDb(r, connection!);
    sut = TypingNotification(r, connection!);
  });

  tearDown(() async {
    sut!.dispose();
    await cleanDb(r, connection!);
  });

  final user = User.fromJson({
    'username': 'Ondina',
    'photoUrl': "https",
    'id': '1234',
    'active': true,
    'lastseen': DateTime.now(),
  });
  final user2 = User.fromJson({
    'username': 'Matei',
    'photoUrl': "https",
    'id': '1235',
    'active': true,
    'lastseen': DateTime.now(),
  });

  test('sent typing notif successfully', () async {
    TypingEvent typingEvent =
        TypingEvent(from: user2.id, to: user.id, event: Typing.start);
    final res = await sut?.send(event: typingEvent, to: user);
    expect(res, true);
  });

  test('successfully subscribe and receive typing events', () async {
    sut?.subscribe(user2, [user.id]).listen(expectAsync1((event) {
      expect(event.from, user.id);
    }, count: 2));

    TypingEvent startTyping =
        TypingEvent(from: user.id, to: user2.id, event: Typing.start);

    TypingEvent stopTyping =
        TypingEvent(from: user.id, to: user2.id, event: Typing.stop);

    await sut?.send(event: startTyping, to: user2);
    await sut?.send(event: stopTyping, to: user2);
  });
}
