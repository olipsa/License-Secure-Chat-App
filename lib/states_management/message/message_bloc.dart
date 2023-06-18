import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat/chat.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/data/services/local_encryption_service.dart';

part 'message_event.dart';
part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final IMessageService _messageService;
  StreamSubscription? _subscription;
  final LocalEncryptionService _localEncryptionService;

  MessageBloc(this._messageService, this._localEncryptionService)
      : super(MessageState.initial());

  @override
  Stream<MessageState> mapEventToState(MessageEvent event) async* {
    if (event is Subscribed) {
      await _subscription?.cancel();
      _subscription = _messageService.messages(activeUser: event.user).listen(
          (message) async => add(_MessageReceived(
              await _localEncryptionService.decryptMessage(message))));
    }

    if (event is _MessageReceived) {
      yield MessageState.received(event.message);
    }
    if (event is MessageSent) {
      Message plaintext = event.message;
      Message ciphertext =
          await _localEncryptionService.encryptMessage(event.message);
      var message = await _messageService.send(ciphertext);
      message.contents = plaintext.contents;
      yield MessageState.sent(message);
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _messageService.dispose();
    return super.close();
  }
}
