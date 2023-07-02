import 'package:bloc/bloc.dart';
import 'package:flutter_chat_app/models/chat_model.dart';
import 'package:flutter_chat_app/viewmodels/chats_view_model.dart';

class ChatsCubit extends Cubit<List<Chat>> {
  final ChatsViewModel viewModel;
  ChatsCubit(this.viewModel) : super([]);

  Future<void> chats() async {
    final chats = await viewModel.getChats();
    emit(chats);
  }

  Future<void> deleteChat(String chatId) async {
    await viewModel.deleteChat(chatId);
  }
}
