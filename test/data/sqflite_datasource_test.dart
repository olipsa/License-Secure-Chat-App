import 'dart:async';

import 'package:chat/chat.dart';
import 'package:flutter_chat_app/data/datasource/sqflite_datasource.dart';
import 'package:flutter_chat_app/models/chat_model.dart';
import 'package:flutter_chat_app/models/local_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';

import 'sqflite_datasource_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Database>(as: #MockSqfliteDatabase)])
// class MockSqfliteDatabase extends Mock implements Database {}

@GenerateNiceMocks([MockSpec<Batch>(as: #MockBatch)])
// class MockBatch extends Mock implements Batch {}

void main() {
  late SqfliteDatasource sut;
  late MockSqfliteDatabase database;
  late MockBatch batch;

  setUp(() {
    database = MockSqfliteDatabase();
    batch = MockBatch();
    sut = SqfliteDatasource(database);
  });

  final message = Message.fromJson({
    'from': '111',
    'to': '112',
    'contents': 'hello',
    'timestamp': DateTime.parse("2023-04-22"),
    'id': '1'
  });

  test('should perform insert of chat to the database', () async {
    final chat = Chat('1234');
    when(database.insert('chats', chat.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .thenAnswer((_) async => 1);
    await sut.addChat(chat);

    verify(database.insert('chats', chat.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .called(1);
  });

  test('should perform insert of message to the database', () async {
    final localMessage = LocalMessage(
        chatId: '1234', message: message, receipt: ReceiptStatus.sent);
    when(database.insert('messages', localMessage.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .thenAnswer((_) async => 1);
    await sut.addMessage(localMessage);

    verify(database.insert('messages', localMessage.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .called(1);
  });

  test('should perform a db query and return messages', () async {
    final messagesMap = [
      {
        'chat_id': '11',
        'id': '444',
        'from': '111',
        'to': '22',
        'contents': 'hi',
        'receipt': 'sent',
        'timestamp': DateTime.parse("2023-04-23")
      }
    ];
    when(database.query(
      'messages',
      where: anyNamed('where'),
      whereArgs: anyNamed('whereArgs'),
    )).thenAnswer((_) async => messagesMap);

    var messages = await sut.findMessages('11');

    expect(messages?.length, 1);
    expect(messages?.first?.chatId, '11');
    verify(database.query(
      'messages',
      where: anyNamed('where'),
      whereArgs: anyNamed('whereArgs'),
    )).called(1);
  });

  test('should perform database update on messages', () async {
    final localMessage = LocalMessage(
        chatId: '1231', message: message, receipt: ReceiptStatus.sent);
    when(database.update('messages', localMessage.toMap(),
            where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
        .thenAnswer((_) async => 1);

    await sut.updateMessage(localMessage);

    verify(database.update('messages', localMessage.toMap(),
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            conflictAlgorithm: ConflictAlgorithm.replace))
        .called(1);
  });

  test('should perform database batch delete of chat', () async {
    const chatId = '111';
    when(database.batch()).thenReturn(batch);

    await sut.deleteChat(chatId);

    verifyInOrder([
      database.batch(),
      batch.delete('messages', where: anyNamed('where'), whereArgs: [chatId]),
      batch.delete('chats', where: anyNamed('where'), whereArgs: [chatId]),
      batch.commit(noResult: true)
    ]);
  });
}
