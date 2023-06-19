// ignore_for_file: public_member_api_docs, sort_constructors_first

enum ContentType { text, image, video }

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
  String contents;
  String? _id;
  int? signalType;
  ContentType contentType;
  String? filePath = '';
  String? fileContents = '';

  Message(
      {required this.from,
      required this.to,
      required this.timestamp,
      required this.contents,
      required this.contentType,
      this.signalType,
      this.fileContents,
      this.filePath});

  toJson() => {
        'from': from,
        'to': to,
        'timestamp': timestamp,
        'contents': contents,
        'signal_type': signalType,
        'content_type': contentType.value(),
        'file_contents': fileContents,
        'file_path': filePath
      };

  factory Message.fromJson(Map<String, dynamic> json) {
    var message = Message(
        from: json['from'],
        to: json['to'],
        timestamp: json['timestamp'],
        contents: json['contents'],
        signalType: json['signal_type'],
        contentType: ContentTypeParsing.fromString(json['content_type']),
        fileContents: json['file_contents'],
        filePath: json['file_path']);
    message._id = json['id'];
    return message;
  }
}
