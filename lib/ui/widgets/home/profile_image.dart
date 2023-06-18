import 'package:flutter/material.dart';
import 'package:flutter_chat_app/ui/widgets/home/online_indicator.dart';

class ProfileImage extends StatelessWidget {
  final String? imageUrl;
  final bool online;

  const ProfileImage({super.key, required this.imageUrl, this.online = false});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(126.0),
            child: Image.network(imageUrl!,
                width: 126, height: 126, fit: BoxFit.fill),
          ),
          Align(
            alignment: Alignment.topRight,
            child: online ? const OnlineIndicator() : Container(),
          )
        ],
      ),
    );
  }
}
