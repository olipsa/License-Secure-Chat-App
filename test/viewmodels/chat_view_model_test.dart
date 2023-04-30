import 'package:chat/chat.dart';
import 'package:flutter_chat_app/data/datasource/datasource_contract.dart';
import 'package:flutter_chat_app/models/chat_model.dart';
import 'package:flutter_chat_app/models/local_message.dart';
import 'package:flutter_chat_app/viewmodels/chat_view_model.dart';
import 'package:flutter_chat_app/viewmodels/chats_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chats_view_model_test.mocks.dart';

@GenerateNiceMocks([MockSpec<IDataSource>(as: #MockDatasource)])
//class MockDatasource extends Mock implements IDataSource {}

void main() {
  late ChatViewModel sut;
  late MockDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockDatasource();
    sut = ChatViewModel(mockDatasource);
  });

  final message = Message.fromJson({
    'from': '111',
    'to': '222',
    'contents': 'hi',
    'timestamp': DateTime.now(),
    'id': '2222'
  });

  test('initial messages return empty list', () async {
    when(mockDatasource.findMessages(any)).thenAnswer((_) async => []);
    expect(await sut.getMessages('123'), isEmpty);
  });

  test('returns list of messages from local storage', () async {
    final chat = Chat('123');
    final localMessage = LocalMessage(
        chatId: chat.id, message: message, receipt: ReceiptStatus.delivered);
    when(mockDatasource.findMessages(chat.id))
        .thenAnswer((_) async => [localMessage]);
    final messages = await sut.getMessages('123');
    expect(messages.first?.chatId, '123');
  });

  test('creates a new chat when sending first message', () async {
    when(mockDatasource.findChat(any)).thenAnswer((_) async => null);
    await sut.sentMessage(message);
    verify(mockDatasource.addChat(any)).called(1);
  });

  test('add new sent message to existing chat', () async {
    final chat = Chat('123');
    final localMessage = LocalMessage(
        chatId: chat.id, message: message, receipt: ReceiptStatus.sent);

    when(mockDatasource.findMessages(chat.id))
        .thenAnswer((_) async => [localMessage]);
    await sut.getMessages(chat.id);
    await sut.sentMessage(message);
    verifyNever(mockDatasource.addChat(any));
    verify(mockDatasource.addMessage(any)).called(1);
  });

  test('add new received message to existing chat', () async {
    final chat = Chat('111');
    final localMessage = LocalMessage(
        chatId: chat.id, message: message, receipt: ReceiptStatus.delivered);

    when(mockDatasource.findMessages(chat.id))
        .thenAnswer((_) async => [localMessage]);
    when(mockDatasource.findChat(chat.id)).thenAnswer((_) async => chat);

    await sut.getMessages(chat.id);
    await sut.receivedMessage(message);

    verifyNever(mockDatasource.addChat(any));
    verify(mockDatasource.addMessage(any)).called(1);
  });

  test('create new chat when message received is not part of current chat',
      () async {
    final chat = Chat('123');
    final localMessage = LocalMessage(
        chatId: chat.id, message: message, receipt: ReceiptStatus.delivered);

    when(mockDatasource.findMessages(chat.id))
        .thenAnswer((_) async => [localMessage]);
    when(mockDatasource.findChat(chat.id)).thenAnswer((_) async => null);

    await sut.getMessages(chat.id);
    await sut.receivedMessage(message);

    verify(mockDatasource.addChat(any)).called(1);
    verify(mockDatasource.addMessage(any)).called(1);
    expect(sut.otherMessages, 1);
  });
}
