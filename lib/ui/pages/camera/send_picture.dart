import 'dart:io';

import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:flutter_chat_app/states_management/message/message_bloc.dart';
import 'package:flutter_chat_app/theme.dart';
import 'package:flutter_chat_app/ui/pages/message_thread/message_thread_router.dart';

class SendPicture extends StatefulWidget {
  final User me;
  final User receiver;
  final String imagePath;
  final MessageBloc messageBloc;
  final IMessageThreadRouter router;
  final String? chatId;
  const SendPicture(this.imagePath, this.me, this.receiver, this.messageBloc,
      this.router, this.chatId,
      {super.key});

  @override
  State<StatefulWidget> createState() => _SendPictureState();
}

class _SendPictureState extends State<SendPicture> {
  final TextEditingController _textEditingController = TextEditingController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var receiverUsername = widget.receiver.username;
    return Scaffold(
      appBar: AppBar(title: Text("Send to $receiverUsername")),
      body: Column(
        children: [
          Expanded(
              child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Image.file(File(widget.imagePath)))),
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildMessageInput(context)),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Container(
                    height: 45.0,
                    width: 45.0,
                    child: RawMaterialButton(
                      fillColor: kPrimary,
                      shape: const CircleBorder(),
                      elevation: 5.0,
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _sendImage();
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildMessageInput(BuildContext context) {
    final border = OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(90.0)),
        borderSide: isLightTheme(context)
            ? BorderSide.none
            : BorderSide(color: Colors.grey.withOpacity(0.3)));
    return Focus(
        onFocusChange: (focus) {},
        child: TextFormField(
          controller: _textEditingController,
          textInputAction: TextInputAction.newline,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          style: Theme.of(context).textTheme.bodySmall,
          cursorColor: kPrimary,
          decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
              enabledBorder: border,
              filled: true,
              fillColor: isLightTheme(context)
                  ? kPrimary.withOpacity(0.1)
                  : kBubbleDark,
              focusedBorder: border,
              hintText: 'Add a description',
              hintStyle: isLightTheme(context)
                  ? const TextStyle(color: Colors.black)
                  : const TextStyle(color: Colors.grey)),
        ));
  }

  _sendImage() {
    if (widget.imagePath == '') return;

    final message = Message(
        from: widget.me.id,
        to: widget.receiver.id,
        timestamp: DateTime.now(),
        contents: _textEditingController.text,
        contentType: ContentType.image,
        filePath: widget.imagePath);
    final sendMessageEvent = MessageEvent.onMessageSent(message);
    widget.messageBloc.add(sendMessageEvent);
    _textEditingController.clear();
    widget.router.onShowMessageThread(context, widget.receiver, widget.me,
        chatId: widget.chatId);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}
