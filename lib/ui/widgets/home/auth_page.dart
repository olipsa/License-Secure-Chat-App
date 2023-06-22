import 'package:flutter/material.dart';
import 'package:flutter_chat_app/data/services/biometric_auth_controller.dart';
import 'package:get/get.dart';

class AuthPage extends GetWidget<AuthController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign in'),
      ),
      body: SafeArea(
        minimum: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(
              size: 150,
            ),
            Text(
              'Welcome',
              style: Get.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 16,
            ),
            _getLoginButton()
          ],
        ),
      ),
    );
  }

  Widget _getLoginButton() {
    return Obx(() {
      if (controller.isBiometricsSupported) {
        return ElevatedButton(
          onPressed: () {
            controller.signInWithBiometrics();
          },
          child: Text('Login with biometrics'),
        );
      } else {
        return Text(
          'Oops, device does not support biometrics',
          style: Get.textTheme.bodyLarge?.copyWith(color: Get.theme.errorColor),
        );
      }
    });
  }
}
