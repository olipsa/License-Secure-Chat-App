import 'package:flutter_chat_app/models/local_message.dart';

import '../../models/chat_model.dart';

abstract class IDataSource {
  Future<void> addChat(Chat chat);
  Future<void> addMessage(LocalMessage message);
  Future<Chat?> findChat(String chatId);
  Future<List<Chat>> findAllChats();
  Future<void> updateMessage(LocalMessage message);
  Future<List<LocalMessage?>> findMessages(String chatId);
  Future<void> deleteChat(String chatId);
}
