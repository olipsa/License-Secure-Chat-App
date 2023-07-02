import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:flutter_chat_app/states_management/onboarding/onboarding_cubit.dart';
import 'package:flutter_chat_app/states_management/onboarding/onboarding_state.dart';
import 'package:flutter_chat_app/states_management/onboarding/profile_image_cubit.dart';
import 'package:flutter_chat_app/ui/pages/onboarding/onboarding_router.dart';
import 'package:flutter_chat_app/ui/pages/onboarding/phone_auth.dart';

import '../../widgets/onboarding/logo.dart';
import '../../widgets/onboarding/profile_upload.dart';
import '../../widgets/shared/custom_text_field.dart';

class Onboarding extends StatefulWidget {
  final IOnboardingRouter router;
  const Onboarding(this.router, {super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  String _username = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _logo(context),
          const Spacer(),
          const ProfileUpload(),
          const Spacer(flex: 1),
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
            child: CustomTextField(
              hint: 'What\'s your name?',
              height: 45.0,
              onchanged: (val) {
                _username = val;
              },
              inputAction: TextInputAction.done,
            ),
          ),
          const SizedBox(height: 30.0),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: ElevatedButton(
                onPressed: () async {
                  final error = _checkInputs();
                  if (error.isNotEmpty) {
                    final snackBar = SnackBar(
                        content: Text(error,
                            style: const TextStyle(
                                fontSize: 14.0, fontWeight: FontWeight.bold)));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    return;
                  }
                  ProfileImageCubit imageCubit =
                      context.read<ProfileImageCubit>();
                  OnboardingCubit onboardingCubit =
                      context.read<OnboardingCubit>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: imageCubit),
                          BlocProvider.value(value: onboardingCubit),
                        ],
                        child: PhoneAuth(_username),
                      ),
                    ),
                  );
                },
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
          const Spacer(flex: 3),
          BlocConsumer<OnboardingCubit, OnboardingState>(
            builder: (context, state) => state is Loading
                ? const Center(child: CircularProgressIndicator())
                : Container(),
            listener: (_, state) {
              if (state is OnboardingSuccess) {
                widget.router.onSessionSuccess(
                    // route to the home screen of the user that just onboarded
                    context,
                    state.user);
              }
            },
          ),
          const Spacer(flex: 1)
        ]),
      ),
    );
  }

  _logo(BuildContext context) {
    final myGroup = AutoSizeGroup();
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            alignment: Alignment.centerRight,
            child: AutoSizeText(
              '    Secure',
              maxLines: 1,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: kPrimary),
            ),
          ),
        ),
        const Logo(),
        Expanded(
          child: Container(
            alignment: Alignment.centerLeft,
            child: AutoSizeText(
              'Messenger',
              maxLines: 1,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: kPrimary),
            ),
          ),
        ),
      ],
    );
  }

  String _checkInputs() {
    var error = '';
    if (_username.isEmpty) error = 'Enter display name';
    return error;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}
