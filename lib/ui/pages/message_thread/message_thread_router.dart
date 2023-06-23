import 'package:chat/chat.dart';
import 'package:flutter/material.dart';

abstract class IMessageThreadRouter {
  Future<void> onShowMessageThread(
    BuildContext context,
    User receiver,
    User me,
  );
  Future<void> onShowPicturePreview(
    BuildContext context,
    User receiver,
    User me,
    String? imagePath,
  );
}

class MessageThreadRouter implements IMessageThreadRouter {
  final Widget Function(User receiver, User me)
      showMessageThread; //shows the message screen
  final Widget Function(
    User receiver,
    User me,
    String? imagePath,
  ) showPicturePreview;

  MessageThreadRouter(
      {required this.showMessageThread, required this.showPicturePreview});

  @override
  Future<void> onShowMessageThread(
    BuildContext context,
    User receiver,
    User me,
  ) {
    return Navigator.push(context,
        MaterialPageRoute(builder: (_) => showMessageThread(receiver, me)));
  }

  @override
  Future<void> onShowPicturePreview(
      BuildContext context, User receiver, User me, String? imagePath,
      {String? chatId}) {
    return Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => showPicturePreview(receiver, me, imagePath)));
  }
}
