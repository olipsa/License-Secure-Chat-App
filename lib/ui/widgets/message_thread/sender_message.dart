import 'dart:io';

import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:flutter_chat_app/models/local_message.dart';
import 'package:flutter_chat_app/theme.dart';
import 'package:flutter_chat_app/ui/widgets/message_thread/full_screen_file.dart';
import 'package:intl/intl.dart';

class SenderMessage extends StatelessWidget {
  // message sent by me
  final LocalMessage _message;
  const SenderMessage(this._message, {super.key});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerRight,
      widthFactor: 0.75,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMessageContent(context, _message.message),
                // message timestamp:
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, left: 12.0),
                  child: Align(
                      alignment: Alignment.bottomRight,
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
          // Receipt status:
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isLightTheme(context) ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: _message.receipt == ReceiptStatus.read
                      ? Colors.green[700]
                      : Colors.grey,
                  size: 20.0,
                ),
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
          color: kPrimary,
          borderRadius: BorderRadius.circular(30),
        ),
        position: DecorationPosition.background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Text(message.contents.trim(),
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
            color: kPrimary,
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
                                senderUsername: 'You',
                              ),
                            ),
                          );
                        },
                      )),
                  if (message.contents.trim().isNotEmpty)
                    const SizedBox(height: 8),
                  if (message.contents.trim().isNotEmpty)
                    Text(message.contents.trim(),
                        softWrap: true,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.2,
                            color: isLightTheme(context)
                                ? Colors.black
                                : Colors.white)),
                ],
              )));
    } else {
      return const SizedBox.shrink();
    }
  }
}
