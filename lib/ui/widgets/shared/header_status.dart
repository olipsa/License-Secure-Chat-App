// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/ui/widgets/home/profile_image.dart';
import 'package:intl/intl.dart';

class HeaderStatus extends StatelessWidget {
  final String username;
  final String? imageUrl;
  final bool online;
  final DateTime? lastSeen;
  final bool? typing;
  final String? phoneNumber;
  const HeaderStatus(
      this.username, this.imageUrl, this.online, this.phoneNumber,
      {super.key, this.lastSeen, this.typing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Row(
        children: [
          ProfileImage(
              imageUrl: imageUrl,
              online: online,
              username: username,
              phoneNumber: phoneNumber),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text(username.trim(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 14.0, fontWeight: FontWeight.bold)),
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: typing == null
                      ? Text(
                          online
                              ? 'online'
                              : 'last seen ${formatDate(lastSeen!)}',
                          style: Theme.of(context).textTheme.bodySmall)
                      : Text('typing..',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic)))
            ],
          )
        ],
      ),
    );
  }
}

String formatDate(DateTime timestamp) {
  String formattedDate;
  DateTime now = DateTime.now();
  DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
  if (timestamp.year == now.year &&
      timestamp.month == now.month &&
      timestamp.day == now.day) {
    formattedDate = 'Today';
  } else if (timestamp.year == yesterday.year &&
      timestamp.month == yesterday.month &&
      timestamp.day == yesterday.day) {
    formattedDate = 'Yesterday';
  } else {
    formattedDate = 'on ${DateFormat('MMMM d, y').format(timestamp)}';
  }
  formattedDate = '$formattedDate, ${DateFormat('h:mm a').format(timestamp)}';

  return formattedDate;
}
