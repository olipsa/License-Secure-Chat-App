import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PassphraseWidget extends StatelessWidget {
  final String passphrase;

  const PassphraseWidget({required this.passphrase});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: passphrase));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passphrase copied to clipboard')),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          passphrase,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
