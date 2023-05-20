// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:rethink_db_ns/rethink_db_ns.dart';

class Message {
  String? get id => _id;
  final String? from;
  final String? to;
  final DateTime? timestamp;
  final String? contents;
  String? _id;

  Message({
    required this.from,
    required this.to,
    required this.timestamp,
    required this.contents,
  });

  toJson() =>
      {'from': from, 'to': to, 'timestamp': timestamp, 'contents': contents};

  factory Message.fromJson(Map<String, dynamic> json) {
    var message = Message(
        from: json['from'],
        to: json['to'],
        timestamp: json['timestamp'],
        contents: json['contents']);
    message._id = json['id'];
    return message;
  }
}
