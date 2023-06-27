import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:get/get.dart';

class PassphraseWidget extends StatelessWidget {
  final String passphrase;

  const PassphraseWidget({required this.passphrase});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security passphrase')),
      body: Column(
        children: [
          SizedBox(
            height: 200,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Copy this passphrase and store it securely, preferably on another device',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8), color: kPrimary),
            child: Text(
              passphrase,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: passphrase));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Passphrase copied to clipboard')),
                  );
                },
                icon: Icon(
                  Icons.copy,
                  color: kPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
