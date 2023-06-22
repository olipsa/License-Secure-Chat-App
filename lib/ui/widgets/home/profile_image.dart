import 'package:flutter/material.dart';
import 'package:flutter_chat_app/ui/widgets/home/online_indicator.dart';

class ProfileImage extends StatelessWidget {
  final String? imageUrl;
  final String? username;
  final bool online;
  final String? phoneNumber;

  const ProfileImage(
      {super.key,
      required this.imageUrl,
      this.online = false,
      required this.username,
      required this.phoneNumber});

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
          appBar: AppBar(
              title: Column(
            children: [
              Text(username!),
              SizedBox(height: 5.0),
              phoneNumber != null
                  ? Text(
                      phoneNumber!,
                      style: TextStyle(
                          color: Color.fromARGB(255, 168, 166, 166),
                          fontSize: 12.0),
                    )
                  : Container(
                      width: 0.0,
                      height: 0.0,
                    )
            ],
          )),
          body: Center(
            child: Image.network(imageUrl!, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
