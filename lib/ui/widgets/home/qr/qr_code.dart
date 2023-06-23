import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/ui/pages/home/home_router.dart';
import 'package:flutter_chat_app/ui/widgets/home/qr/qr_code_me.dart';
import 'package:flutter_chat_app/ui/widgets/home/qr/qr_code_scanner.dart';

class QrCode extends StatelessWidget {
  final IUserService userService;
  final User me;
  final IHomeRouter router;

  QrCode({required this.userService, required this.me, required this.router});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              title: Text('QR Code',
                  style: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
              bottom: TabBar(
                indicatorPadding:
                    const EdgeInsets.only(top: 10.0, bottom: 10.0),
                tabs: [
                  Tab(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Align(
                        alignment: Alignment.center,
                        child: Text(
                          'My QR code',
                        ),
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Scan QR code',
                          )),
                    ),
                  ),
                ],
              ),
            ),
            body: TabBarView(children: [
              QrCodeMe(me.id!),
              QrCodeScanner(userService, me, router)
            ])));
  }
}
