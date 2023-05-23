part of 'typing_notification_bloc.dart';

abstract class TypingNotificationEvent extends Equatable {
  const TypingNotificationEvent();
  factory TypingNotificationEvent.onSubscribed(User user,
          {required List<String?> usersWithChat}) =>
      Subscribed(user, usersWithChat: usersWithChat);
  factory TypingNotificationEvent.onTypingEventSent(TypingEvent event) =>
      TypingNotificationSent(event);

  @override
  List<Object?> get props => [];
}

class Subscribed extends TypingNotificationEvent {
  //used whenever client subscribes to receive Receipts
  final User user;
  final List<String?> usersWithChat;
  const Subscribed(this.user, {required this.usersWithChat});

  @override
  List<Object?> get props => [user, usersWithChat];
}

class NotSubscribed extends TypingNotificationEvent {}

class TypingNotificationSent extends TypingNotificationEvent {
  final TypingEvent event;
  const TypingNotificationSent(this.event);
  @override
  List<Object?> get props => [event];
}

class _TypingNotificationReceived extends TypingNotificationEvent {
  const _TypingNotificationReceived(this.event);
  final TypingEvent event;

  @override
  List<Object?> get props => [event];
}
