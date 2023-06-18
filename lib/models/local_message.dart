// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:chat/chat.dart';

class LocalMessage {
  String? chatId;
  String get id => _id;
  late String _id;
  Message message;
  ReceiptStatus receipt;

  LocalMessage({
    required this.chatId,
    required this.message,
    required this.receipt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'chat_id': chatId,
      'id': message.id,
      'sender': message.from,
      'receiver': message.to,
      'contents': message.contents,
      'receipt': receipt.value(),
      'received_at': message.timestamp.toString(),
      'content_type': message.contentType.value(),
      'file_path': message.filePath
    };
  }

  factory LocalMessage.fromMap(Map<String, dynamic> json) {
    final message = Message(
        from: json['sender'],
        to: json['receiver'],
        timestamp: DateTime.parse(json['received_at']),
        contents: json['contents'],
        contentType: ContentTypeParsing.fromString(json['content_type']),
        filePath: json['file_path']);

    final localMessage = LocalMessage(
        chatId: json['chat_id'],
        message: message,
        receipt: EnumParsing.fromString(json['receipt']));
    localMessage._id = json['id'];
    return localMessage;
  }
}
