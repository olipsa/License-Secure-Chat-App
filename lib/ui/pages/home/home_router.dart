import 'package:chat/chat.dart';
import 'package:flutter/material.dart';

abstract class IHomeRouter {
  Future<void> onShowMessageThread(
      BuildContext context, User receiver, User me);
}

class HomeRouter implements IHomeRouter {
  final Widget Function(User receiver, User me)
      showMessageThread; //shows the message thread screen

  HomeRouter({required this.showMessageThread});

  @override
  Future<void> onShowMessageThread(
      BuildContext context, User receiver, User me) {
    return Navigator.push(context,
        MaterialPageRoute(builder: (_) => showMessageThread(receiver, me)));
  }
}
