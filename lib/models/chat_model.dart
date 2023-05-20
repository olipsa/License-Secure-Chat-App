// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:chat/chat.dart';
import 'package:flutter_chat_app/models/local_message.dart';

class Chat {
  String? id;
  int unread = 0;
  List<LocalMessage>? messageList = [];
  LocalMessage? mostRecent;
  late User from;
  Chat(
    this.id, {
    this.messageList,
    this.mostRecent,
  });

  toMap() => {'id': id};
  factory Chat.fromMap(Map<String, dynamic> json) => Chat(json['id']);
}
