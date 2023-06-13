import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_chat_app/models/local_message.dart';
import 'package:flutter_chat_app/viewmodels/chat_view_model.dart';

class MessageThreadCubit extends Cubit<List<LocalMessage>> {
  final ChatViewModel viewModel;
  MessageThreadCubit(this.viewModel) : super([]);

  Future<void> messages(String? chatId) async {
    final messages = await viewModel.getMessages(chatId);
    // tbd: decrypt all messages
    emit(messages);
  }
}
