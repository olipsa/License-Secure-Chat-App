// ignore_for_file: public_member_api_docs, sort_constructors_first

enum ContentType { text, image, video, voice }

extension ContentTypeParsing on ContentType {
  String value() {
    return toString().split('.').last; //ReceiptStatus.sent is this.toString
  }

  static ContentType fromString(String status) {
    return ContentType.values.firstWhere((element) =>
        element.value() == status); // the enum reperesentation of the status
  }
}

class Message {
  String? get id => _id;
  final String? from;
  final String? to;
  final DateTime timestamp;
  Map<String, dynamic> contents;
  String? _id;
  int? signalType;
  ContentType contentType;
  String? filePath = '';
  // Map<String, dynamic>? fileContents;

  Message(
      {required this.from,
      required this.to,
      required this.timestamp,
      required this.contents,
      required this.contentType,
      this.signalType,
      this.filePath});

  toJson() => {
        'from': from,
        'to': to,
        'timestamp': timestamp,
        'contents': contents['encrypted_content'],
        'signal_type': signalType,
        'content_type': contentType.value(),
        'file_path': filePath
      };

  factory Message.fromJson(Map<String, dynamic> messageJson) {
    var message = Message(
        from: messageJson['from'],
        to: messageJson['to'],
        timestamp: messageJson['timestamp'],
        contents: {'encrypted_content': messageJson['contents']},
        signalType: messageJson['signal_type'],
        contentType: ContentTypeParsing.fromString(messageJson['content_type']),
        filePath: messageJson['file_path']);
    message._id = messageJson['id'];
    return message;
  }
}
