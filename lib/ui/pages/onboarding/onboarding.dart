import 'package:flutter/material.dart';
import 'package:flutter_chat_app/colors.dart';

import '../../widgets/onboarding/logo.dart';
import '../../widgets/onboarding/profile_upload.dart';
import '../../widgets/shared/custom_text_field.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            _logo(context),
            const Spacer(),
            const ProfileUpload(),
            const Spacer(flex: 1),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: CustomTextField(
                  hint: 'What\'s your name?',
                  height: 45.0,
                  onchanged: (val) {},
                  inputAction: TextInputAction.done),
            ),
            const SizedBox(height: 30.0),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      elevation: 5.0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(45.0))),
                  child: Container(
                    height: 45.0,
                    alignment: Alignment.center,
                    child: Text(
                      'Join Secure Messenger!',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 18.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  )),
            ),
            const Spacer(flex: 2)
          ]),
        ),
      ),
    );
  }

  _logo(BuildContext context) {
    return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '   Secure',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: kPrimary),
          ),
          const SizedBox(width: 8.0),
          const Logo(),
          const SizedBox(width: 8.0),
          Text(
            'Messenger',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: kPrimary),
          ),
        ]);
  }
}
