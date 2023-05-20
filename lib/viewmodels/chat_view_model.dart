import 'package:chat/chat.dart';
import 'package:flutter_chat_app/data/datasource/datasource_contract.dart';
import 'package:flutter_chat_app/models/local_message.dart';
import 'package:flutter_chat_app/viewmodels/base_view_model.dart';

class ChatViewModel extends BaseViewModel {
  IDataSource _dataSource;
  String _chatId = '';
  int otherMessages = 0;

  ChatViewModel(this._dataSource) : super(_dataSource);

  Future<List<LocalMessage?>> getMessages(String? chatId) async {
    final messages = await _dataSource.findMessages(chatId!);
    if (messages.isNotEmpty) _chatId = chatId;
    return messages;
  }

  Future<void> sentMessage(Message message) async {
    LocalMessage localMessage = LocalMessage(
        chatId: message.to, message: message, receipt: ReceiptStatus.sent);
    if (_chatId != '') {
      //it's an already existing chat
      return await _dataSource.addMessage(localMessage);
    }
    _chatId = localMessage.chatId!;
    await addMessage(localMessage);
  }

  Future<void> receivedMessage(Message message) async {
    LocalMessage localMessage = LocalMessage(
        chatId: message.from,
        message: message,
        receipt: ReceiptStatus.delivered);
    if (localMessage.chatId != _chatId) {
      //received message that's not part of this chat
      otherMessages++;
    }
    await addMessage(localMessage);
  }
}
