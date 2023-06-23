import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeMe extends StatelessWidget {
  final String userId;
  const QrCodeMe(this.userId, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Add me to your friends list',
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 30.0,
              ),
              QrImageView(
                data: userId,
                version: QrVersions.auto,
                size: 300.0,
                backgroundColor: Colors.white,
              ),
            ]),
      ),
    );
  }
}
