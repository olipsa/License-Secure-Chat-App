// ignore_for_file: public_member_api_docs, sort_constructors_first

class Message {
  String? get id => _id;
  final String? from;
  final String? to;
  final DateTime timestamp;
  String contents;
  String? _id;
  int? type;

  Message(
      {required this.from,
      required this.to,
      required this.timestamp,
      required this.contents,
      this.type});

  toJson() => {
        'from': from,
        'to': to,
        'timestamp': timestamp,
        'contents': contents,
        'type': type
      };

  factory Message.fromJson(Map<String, dynamic> json) {
    var message = Message(
        from: json['from'],
        to: json['to'],
        timestamp: json['timestamp'],
        contents: json['contents'],
        type: json['type']);
    message._id = json['id'];
    return message;
  }
}
