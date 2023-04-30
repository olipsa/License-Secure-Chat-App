import 'package:chat/chat.dart';
import 'package:flutter_chat_app/data/datasource/datasource_contract.dart';
import 'package:flutter_chat_app/models/chat_model.dart';
import 'package:flutter_chat_app/viewmodels/chats_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chats_view_model_test.mocks.dart';

@GenerateNiceMocks([MockSpec<IDataSource>(as: #MockDatasource)])
//class MockDatasource extends Mock implements IDataSource {}

void main() {
  late ChatsViewModel sut;
  late MockDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockDatasource();
    sut = ChatsViewModel(mockDatasource);
  });

  final message = Message.fromJson({
    'from': '123',
    'to': '122',
    'contents': 'hi',
    'timestamp': DateTime.now(),
    'id': '2222'
  });

  test('initial chats return empty list', () async {
    when(mockDatasource.findAllChats()).thenAnswer((_) async => []);
    expect(await sut.getChats(), isEmpty);
  });

  test('returns list of chats', () async {
    final chat = Chat('123');
    when(mockDatasource.findAllChats()).thenAnswer((_) async => [chat]);
    final listOfChats = await sut.getChats();
    expect(listOfChats, [chat]);
  });

  test('creates a new chat when receiving message for the first time',
      () async {
    when(mockDatasource.findChat(any)).thenAnswer((_) async => null);
    await sut.receivedMessage(message);
    verify(mockDatasource.addChat(any)).called(1);
  });

  test('add new message to existing chat', () async {
    final chat = Chat('123');

    when(mockDatasource.findChat(chat.id)).thenAnswer((_) async => chat);
    await sut.receivedMessage(message);
    verifyNever(mockDatasource.addChat(any));
    verify(mockDatasource.addMessage(any)).called(1);
  });
}
