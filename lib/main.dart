import 'package:flutter/material.dart';
import 'package:flutter_chat_app/theme.dart';
import 'package:flutter_chat_app/ui/pages/onboarding/onboarding.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Secure Messenger',
        theme: lightTheme(context),
        darkTheme: darkTheme(context),
        home: const Onboarding());
  }
}
