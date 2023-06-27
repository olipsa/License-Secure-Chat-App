import 'dart:io';

import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:flutter_chat_app/models/local_message.dart';
import 'package:flutter_chat_app/theme.dart';
import 'package:flutter_chat_app/ui/widgets/message_thread/full_screen_file.dart';
import 'package:flutter_chat_app/ui/widgets/message_thread/video_thumbnail.dart';
import 'package:intl/intl.dart';

class ReceiverMessage extends StatelessWidget {
  // message received
  final String? _url;
  final LocalMessage _message;
  final String senderUsername;
  const ReceiverMessage(this._message, this._url, this.senderUsername,
      {super.key});

  @override
  Widget build(BuildContext context) {
    // message bubble
    return FractionallySizedBox(
      alignment: Alignment.topLeft,
      widthFactor: 0.75,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMessageContent(context, _message.message),
                // message timestamp:
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, left: 12.0),
                  child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        DateFormat('h:mm a').format(_message.message.timestamp),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isLightTheme(context)
                                  ? Colors.black54
                                  : Colors.white70,
                            ),
                      )),
                ),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: isLightTheme(context)
                ? Colors.white
                : const Color.fromARGB(255, 22, 23, 22),
            radius: 18,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Image.network(
                _url!,
                width: 30,
                height: 30,
                fit: BoxFit.fill,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, Message message) {
    if (message.contentType == ContentType.text) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: isLightTheme(context) ? kBubbleLight : kBubbleDark,
          borderRadius: BorderRadius.circular(30),
        ),
        position: DecorationPosition.background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Text(message.contents['text'].trim(),
              softWrap: true,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.2,
                  color: isLightTheme(context) ? Colors.black : Colors.white)),
        ),
      );
    } else if (message.contentType == ContentType.image) {
      File imageFile = File(message.filePath!);
      return DecoratedBox(
          decoration: BoxDecoration(
            color: isLightTheme(context) ? kBubbleLight : kBubbleDark,
            borderRadius: BorderRadius.circular(10),
          ),
          position: DecorationPosition.background,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: GestureDetector(
                        child: Image.file(imageFile,
                            width: 150, height: 150, fit: BoxFit.cover),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImage(
                                imageFile: imageFile,
                                timestamp: message.timestamp,
                                senderUsername: senderUsername,
                              ),
                            ),
                          );
                        },
                      )),
                  if (message.contents['text'].trim().isNotEmpty)
                    const SizedBox(height: 8),
                  if (message.contents['text'].trim().isNotEmpty)
                    Text(message.contents['text'].trim(),
                        softWrap: true,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.2,
                            color: isLightTheme(context)
                                ? Colors.black
                                : Colors.white)),
                ],
              )));
    } else if (message.contentType == ContentType.video) {
      return Video(videoPath: message.filePath!);
    } else {
      return const SizedBox.shrink();
    }
  }
}
