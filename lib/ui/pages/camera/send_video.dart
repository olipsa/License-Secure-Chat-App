import 'dart:convert';
import 'dart:io';

import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:flutter_chat_app/states_management/message/message_bloc.dart';
import 'package:flutter_chat_app/theme.dart';
import 'package:flutter_chat_app/ui/pages/message_thread/message_thread_router.dart';
import 'package:video_player/video_player.dart';

class SendVideo extends StatefulWidget {
  final User me;
  final User receiver;
  final String videoPath;
  final MessageBloc messageBloc;
  final IMessageThreadRouter router;
  final String? chatId;
  const SendVideo(this.videoPath, this.me, this.receiver, this.messageBloc,
      this.router, this.chatId,
      {super.key});

  @override
  State<StatefulWidget> createState() => _SendVideoState();
}

class _SendVideoState extends State<SendVideo> {
  final TextEditingController _textEditingController = TextEditingController();
  late VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {
          _controller.setLooping(true);
          _controller.play();
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    var receiverUsername = widget.receiver.username;
    return Scaffold(
      appBar: AppBar(title: Text("Send to $receiverUsername")),
      body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _controller.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      : CircularProgressIndicator(),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildMessageInput(context)),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
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
                            _sendVideo();
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          )),
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
        child: Container(
          margin: const EdgeInsets.all(8.0),
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
          ),
        ));
  }

  _sendVideo() async {
    if (widget.videoPath == '') return;

    final videoBytes = await File(widget.videoPath).readAsBytes();
    final description = _textEditingController.text;
    Map<String, dynamic> videoWithDescription = {
      "file": videoBytes,
      "text": description,
    };

    final message = Message(
        from: widget.me.id,
        to: widget.receiver.id,
        timestamp: DateTime.now(),
        contents: videoWithDescription,
        contentType: ContentType.video,
        filePath: widget.videoPath);
    final sendMessageEvent = MessageEvent.onMessageSent(message);
    widget.messageBloc.add(sendMessageEvent);
    _textEditingController.clear();
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}
