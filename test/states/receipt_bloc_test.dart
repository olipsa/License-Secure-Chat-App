import 'package:chat/chat.dart';
import 'package:flutter_chat_app/states_management/receipt/receipt_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'receipt_bloc_test.mocks.dart';

@GenerateNiceMocks([MockSpec<IReceiptService>(as: #FakeReceiptService)])
void main() {
  late ReceiptBloc sut;
  late IReceiptService receiptService;
  late User user;

  setUp(() {
    receiptService = FakeReceiptService();
    user = User(
        username: 'test',
        photoUrl: 'photoUrl',
        active: true,
        lastseen: DateTime.now());
    sut = ReceiptBloc(receiptService);
  });

  tearDown(() => sut.close());

  test('should send the initial state only when there are no subscriptions',
      () {
    expect(sut.state, ReceiptInitial());
  });

  test('should send receipt sent state when receipt is sent', () {
    final receipt = Receipt(
        recipient: '123',
        messageId: '222',
        status: ReceiptStatus.sent,
        timestamp: DateTime.now());

    when(receiptService.send(receipt)).thenAnswer((_) async => true);
    sut.add(ReceiptEvent.onReceiptSent(receipt));
    expectLater(sut.stream, emits(ReceiptState.sent(receipt)));
  });

  test('should send Receipt reveived state when Receipt is received', () {
    final receipt = Receipt(
        recipient: '123',
        messageId: '222',
        status: ReceiptStatus.sent,
        timestamp: DateTime.now());
    when(receiptService.receipts(user))
        .thenAnswer((_) => Stream.fromIterable([receipt]));
    sut.add(ReceiptEvent.onSubscribed(user));
    expectLater(sut.stream, emitsInOrder([ReceiptReceivedSuccess(receipt)]));
  });
}
