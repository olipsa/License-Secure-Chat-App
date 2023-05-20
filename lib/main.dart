import 'package:flutter/material.dart';
import 'package:flutter_chat_app/composition_root.dart';
import 'package:flutter_chat_app/theme.dart';
import 'package:flutter_chat_app/ui/pages/home/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CompositionRoot.configure();
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
        home: CompositionRoot.composeHomeUi());
  }
}
