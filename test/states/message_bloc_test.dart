import 'package:chat/chat.dart';
import 'package:flutter_chat_app/states_management/message/message_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'message_bloc_test.mocks.dart';

@GenerateNiceMocks([MockSpec<IMessageService>(as: #FakeMessageService)])
void main() {
  late MessageBloc sut;
  late IMessageService messageService;
  late User user;

  setUp(() {
    messageService = FakeMessageService();
    user = User(
        username: 'test',
        photoUrl: 'photoUrl',
        active: true,
        lastseen: DateTime.now());
    sut = MessageBloc(messageService);
  });

  tearDown(() => sut.close());

  test('should send the initial state only when there are no subscriptions',
      () {
    expect(sut.state, MessageInitial());
  });

  test('should send message sent state when message is sent', () {
    final message = Message(
        from: '123',
        to: '456',
        timestamp: DateTime.now(),
        contents: 'test message');

    when(messageService.send(message)).thenAnswer((_) async => true);
    sut.add(MessageEvent.onMessageSent(message));
    expectLater(sut.stream, emits(MessageState.sent(message)));
  });

  test('should send message reveived state when message is received', () {
    final message = Message(
        from: '123',
        to: '456',
        timestamp: DateTime.now(),
        contents: 'test message');
    when(messageService.messages(activeUser: user))
        .thenAnswer((_) => Stream.fromIterable([message]));
    sut.add(MessageEvent.onSubscribed(user));
    expectLater(sut.stream, emitsInOrder([MessageReceivedSuccess(message)]));
  });
}
