import 'package:flutter/material.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:flutter_chat_app/theme.dart';

class OnlineIndicator extends StatelessWidget {
  const OnlineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 15.0,
      width: 15.0,
      decoration: BoxDecoration(
          color: kIndicatorBubble,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
              width: 3.0,
              color: isLightTheme(context) ? Colors.white : Colors.black)),
    );
  }
}
