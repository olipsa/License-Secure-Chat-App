// ignore_for_file: public_member_api_docs, sort_constructors_first
enum ReceiptStatus { sent, delivered, read }

extension EnumParsing on ReceiptStatus {
  String value() {
    return toString().split('.').last; //ReceiptStatus.sent is this.toString
  }

  static ReceiptStatus fromString(String status) {
    return ReceiptStatus.values.firstWhere((element) =>
        element.value() == status); // the enum reperesentation of the status
  }
}

class Receipt {
  final String recipient;
  final String messageId;
  final ReceiptStatus status;
  final DateTime timestamp;
  String _id = '';
  String get id => _id;

  Receipt({
    required this.recipient,
    required this.messageId,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'recipient': recipient,
        'message_id': messageId,
        'status': status.value(),
        'timestamp': timestamp
      };

  factory Receipt.fromJson(Map<String, dynamic> json) {
    var receipt = Receipt(
        recipient: json['recipient'],
        messageId: json['message_id'],
        status: EnumParsing.fromString(json['status']),
        timestamp: json['timestamp']);
    receipt._id = json['id'];
    return receipt;
  }
}
