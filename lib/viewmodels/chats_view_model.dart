import 'package:chat/chat.dart';
import 'package:flutter_chat_app/data/datasource/datasource_contract.dart';
import 'package:flutter_chat_app/models/local_message.dart';
import 'package:flutter_chat_app/viewmodels/base_view_model.dart';

import '../models/chat_model.dart';

class ChatsViewModel extends BaseViewModel {
  IDataSource _dataSource;

  ChatsViewModel(this._dataSource) : super(_dataSource);

  Future<List<Chat>> getChats() async => await _dataSource.findAllChats();

  Future<void> receivedMessage(Message message) async {
    LocalMessage localMessage = LocalMessage(
        chatId: message.from,
        message: message,
        receipt: ReceiptStatus.delivered);
    await addMessage(localMessage); //adds the message to the correct chat
  }
}
