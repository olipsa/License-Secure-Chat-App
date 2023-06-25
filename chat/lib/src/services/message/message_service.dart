// ignore_for_file: avoid_print

import 'dart:async';

import 'package:chat/chat.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

class MessageService implements IMessageService {
  final Connection _connection;
  final RethinkDb r;
  final StreamController<Message> _controller =
      StreamController<Message>.broadcast();
  StreamSubscription? _changefeed;

  MessageService(this.r, this._connection);

  @override
  dispose() {
    _changefeed?.cancel();
    _controller.close();
  }

  @override
  Stream<Message> messages({required User activeUser}) {
    _startReceivingMessages(activeUser);
    return _controller.stream;
  }

  @override
  Future<Message> send(Message message) async {
    var data = message.toJson();
    data.remove('file_path');

    Map record = await r
        .table('messages')
        .insert(data, {'return_changes': true}).run(_connection);
    Message returnedMessage =
        Message.fromJson(record['changes'].first['new_val']);
    return returnedMessage;
  }

  _startReceivingMessages(User user) {
    _changefeed = r
        .table('messages')
        .filter({'to': user.id})
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event
              .forEach((feedData) async {
                if (feedData['new_val'] == null) return; // no new messages

                final message = await _messageFromFeed(feedData);
                _controller.sink.add(
                    message); //message added to the stream so that client can receive it
                _removeDeliverredMessage(message);
              })
              .catchError((err) => print(err))
              .onError((error, stackTrace) => print(error));
        }); //will send all messages that were sent before subscribing
  }

  Future<Message> _messageFromFeed(feedData) async {
    var data = feedData['new_val'];
    return Message.fromJson(data); // return encrypted message
  }

  _removeDeliverredMessage(Message message) {
    r
        .table('messages')
        .get(message.id)
        .delete({'return_changes': false}).run(_connection);
  }
}
