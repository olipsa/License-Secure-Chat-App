// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:flutter_chat_app/theme.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final Function(String val) onchanged;
  final double height;
  final TextInputAction inputAction;

  const CustomTextField(
      {super.key,
      required this.hint,
      required this.onchanged,
      this.height = 54.0,
      required this.inputAction});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: height,
        decoration: BoxDecoration(
            color: isLightTheme(context) ? Colors.white : kBubbleDark,
            borderRadius: BorderRadius.circular(45.0),
            border: Border.all(
                color: isLightTheme(context)
                    ? const Color(0xFFC4C4C4)
                    : const Color(0xFF393737),
                width: 1.5)),
        child: TextField(
          keyboardType: TextInputType.text,
          onChanged: onchanged,
          textInputAction: inputAction,
          style: isLightTheme(context)
              ? const TextStyle(color: Colors.black)
              : const TextStyle(color: Colors.white),
          cursorColor: kPrimary,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
            hintText: hint,
            hintStyle: isLightTheme(context)
                ? const TextStyle(color: Colors.black)
                : const TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
        ));
  }
}
