import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat/chat.dart';
import 'package:equatable/equatable.dart';

part 'typing_notification_event.dart';
part 'typing_notification_state.dart';

class TypingNotificationBloc
    extends Bloc<TypingNotificationEvent, TypingNotificationState> {
  final ITypingNotification _typingNotification;
  StreamSubscription? _subscription;

  TypingNotificationBloc(this._typingNotification)
      : super(TypingNotificationState.initial());

  @override
  Stream<TypingNotificationState> mapEventToState(
      TypingNotificationEvent event) async* {
    if (event is Subscribed) {
      if (event.usersWithChat == []) {
        //to save memory
        add(NotSubscribed());
        return;
      }
      await _subscription?.cancel();
      _subscription = _typingNotification
          .subscribe(event.user, event.usersWithChat)
          .listen((event) => add(_TypingNotificationReceived(event)));
    }

    if (event is _TypingNotificationReceived) {
      yield TypingNotificationState.received(event.event);
    }
    if (event is TypingNotificationSent) {
      await _typingNotification.send(event: event.event);
      yield TypingNotificationState.sent();
    }

    if (event is NotSubscribed) {
      yield TypingNotificationState.initial();
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _typingNotification.dispose();
    return super.close();
  }
}
