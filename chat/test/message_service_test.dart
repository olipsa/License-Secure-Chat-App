import 'package:chat/src/models/message.dart';
import 'package:chat/src/services/encryption/encryption_service.dart';
import 'package:chat/src/services/message/message_service.dart';
import 'package:chat/src/models/user.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'helpers.dart';

void main() {
  RethinkDb r = RethinkDb();
  Connection? connection;
  late MessageService messageService;

  setUp(() async {
    connection = await r.connect();
    final encryption = EncryptionService(Encrypter(AES(Key.fromLength(32))));
    await createDb(r, connection!);
    messageService = MessageService(r, connection!, encryption);
  });

  tearDown(() async {
    messageService.dispose();
    await cleanDb(r, connection!);
  });

  final user = User.fromJson({
    'username': 'Ondina',
    'photoUrl': "https",
    'id': '1234',
    'active': true,
    'lastseen': DateTime.now()
  });

  final user2 = User.fromJson({
    'username': 'Ondina',
    'photoUrl': "https",
    'id': '1235',
    'active': true,
    'lastseen': DateTime.now()
  });

  test('sent message successfully', () async {
    Message message = Message(
        from: user.id,
        to: 'doesnt matter',
        timestamp: DateTime.now(),
        contents: 'Hello!');
    final res = await messageService.send(message);
    expect(res, true);
  });

  test('successfully subscribed and received messages', () async {
    final contents = 'this is a message';
    messageService.messages(activeUser: user2).listen(expectAsync1((message) {
          expect(message.to, user2.id);
          expect(message.id, isNotEmpty);
          expect(message.contents, contents);
        }, count: 2)); //expected that this method will be executed twice

    Message message = Message(
        from: user.id,
        to: user2.id,
        timestamp: DateTime.now(),
        contents: contents);
    Message message2 = Message(
        from: user.id,
        to: user2.id,
        timestamp: DateTime.now(),
        contents: contents);

    await messageService.send(message);
    await messageService.send(message2);
  });
  test('successfully subscribe and receive new messages', () async {
    Message message = Message(
        from: user.id,
        to: user2.id,
        timestamp: DateTime.now(),
        contents: 'Hello from user!');
    Message message2 = Message(
        from: user.id,
        to: user2.id,
        timestamp: DateTime.now(),
        contents: 'Hello from user again!');

    await messageService.send(message);
    await messageService
        .send(message2)
        .whenComplete(() => messageService.messages(activeUser: user2).listen(
              expectAsync1((message) {
                expect(message.to, user2.id);
              }, count: 2),
            ));
  });
}
