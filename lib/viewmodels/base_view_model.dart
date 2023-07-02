import 'package:flutter/cupertino.dart';
import 'package:flutter_chat_app/data/datasource/datasource_contract.dart';
import 'package:flutter_chat_app/models/chat_model.dart';
import 'package:flutter_chat_app/models/local_message.dart';

abstract class BaseViewModel {
  final IDataSource _datasource;

  BaseViewModel(
    this._datasource,
  );

  @protected
  Future<void> addMessage(LocalMessage message) async {
    // adds new received and sent messages to the local db
    if (!await _isExistingChat(message.chatId)) {
      await _createNewChat(message.chatId);
    }
    await _datasource.addMessage(message);
  }

  Future<bool> _isExistingChat(String? chatId) async {
    return await _datasource.findChat(chatId) != null;
  }

  Future<void> _createNewChat(String? chatId) async {
    final chat = Chat(chatId);
    await _datasource.addChat(chat);
  }

  Future<void> deleteChat(String chatId) async {
    await _datasource.deleteChat(chatId); //adds the message to local db
  }
}
