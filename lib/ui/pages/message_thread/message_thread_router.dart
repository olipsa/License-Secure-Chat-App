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
  Future<void> onShowVideoPreview(
    BuildContext context,
    User receiver,
    User me,
    String? videoPath,
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
  final Widget Function(
    User receiver,
    User me,
    String? imagePath,
  ) showVideoPreview;

  MessageThreadRouter(
      {required this.showMessageThread,
      required this.showPicturePreview,
      required this.showVideoPreview});

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

  @override
  Future<void> onShowVideoPreview(
      BuildContext context, User receiver, User me, String? videoPath,
      {String? chatId}) {
    return Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => showVideoPreview(receiver, me, videoPath)));
  }
}
