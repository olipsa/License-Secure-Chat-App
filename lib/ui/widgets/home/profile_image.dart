import 'package:flutter/material.dart';
import 'package:flutter_chat_app/ui/widgets/home/online_indicator.dart';

class ProfileImage extends StatelessWidget {
  final String? imageUrl;
  final String? username;
  final bool online;

  const ProfileImage(
      {super.key,
      required this.imageUrl,
      this.online = false,
      required this.username});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(126.0),
            child: GestureDetector(
              onTap: () => _showExpandedImage(context, imageUrl),
              child: Image.network(imageUrl!,
                  width: 126, height: 126, fit: BoxFit.fill),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: online ? const OnlineIndicator() : Container(),
          )
        ],
      ),
    );
  }

  void _showExpandedImage(BuildContext context, String? imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(username!)),
          body: Center(
            child: Image.network(imageUrl!, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
