import 'package:flutter/material.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:flutter_chat_app/theme.dart';

class ProfileUpload extends StatelessWidget {
  const ProfileUpload();

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 126.0,
        width: 126.0,
        child: Material(
            color: isLightTheme(context)
                ? Color.fromARGB(141, 197, 130, 204)
                : Color.fromARGB(255, 72, 71, 71),
            borderRadius: BorderRadius.circular(126.0),
            child: InkWell(
                borderRadius: BorderRadius.circular(126.0),
                onTap: () {},
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 126.0,
                          color:
                              isLightTheme(context) ? kIconLight : Colors.black,
                        )),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.add_circle_rounded,
                          color: kPrimary, size: 38.0),
                    )
                  ],
                ))));
  }
}
