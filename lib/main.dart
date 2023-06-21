import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/composition_root.dart';
import 'package:flutter_chat_app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await CompositionRoot.configure();
  final firstPage = CompositionRoot.start();
  runApp(MyApp(firstPage));
}

class MyApp extends StatelessWidget {
  final Widget firstPage;

  const MyApp(this.firstPage, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Messenger',
      theme: lightTheme(context),
      darkTheme: darkTheme(context),
      home: firstPage,
    );
  }
}
