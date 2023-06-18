import 'package:chat/chat.dart';
import 'package:flutter_chat_app/data/datasource/datasource_contract.dart';
import 'package:flutter_chat_app/models/chat_model.dart';
import 'package:flutter_chat_app/models/local_message.dart';
import 'package:flutter_chat_app/viewmodels/base_view_model.dart';

class ChatsViewModel extends BaseViewModel {
  final IDataSource _dataSource;
  final IUserService _userService;

  ChatsViewModel(this._dataSource, this._userService) : super(_dataSource);

  Future<List<Chat>> getChats() async {
    final chats = await _dataSource.findAllChats();
    await Future.forEach(chats, (chat) async {
      final user = await _userService.fetch(chat.id);
      chat.from = user;
    });

    return chats;
  }

  Future<void> receivedMessage(Message message) async {
    LocalMessage localMessage = LocalMessage(
        chatId: message.from,
        message: message,
        receipt: ReceiptStatus.delivered);
    await addMessage(localMessage); //adds the message to local db
  }
}
