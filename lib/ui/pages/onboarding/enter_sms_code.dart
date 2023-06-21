import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:flutter_chat_app/states_management/onboarding/onboarding_cubit.dart';
import 'package:flutter_chat_app/states_management/onboarding/profile_image_cubit.dart';
import 'package:flutter_chat_app/theme.dart';
import 'package:flutter_countdown_timer/current_remaining_time.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class EnterSmsCodePage extends StatefulWidget {
  final String _phoneNumber;
  String _verificationId;
  final String _username;

  EnterSmsCodePage(this._phoneNumber, this._verificationId, this._username);

  @override
  _EnterSmsCodePageState createState() => _EnterSmsCodePageState();
}

class _EnterSmsCodePageState extends State<EnterSmsCodePage> {
  final TextEditingController _smsCodeController = TextEditingController();
  int expirationTime = 30;
  int secondsRemaining = 30;
  bool enableResend = false;
  late Timer timer;
  late int endTime;
  bool isResending = false;

  @override
  void initState() {
    super.initState();
    endTime = DateTime.now().millisecondsSinceEpoch +
        Duration(seconds: expirationTime).inMilliseconds;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsRemaining != 0) {
        setState(() {
          secondsRemaining--;
        });
      } else {
        setState(() {
          enableResend = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    TextStyle textColor = isLightTheme(context)
        ? const TextStyle(color: Colors.black)
        : const TextStyle(color: Colors.white);
    return Scaffold(
      appBar: AppBar(
        title: Text("Enter SMS Code"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CountdownTimer(
              endTime: endTime,
              widgetBuilder:
                  (BuildContext context, CurrentRemainingTime? time) {
                if (time == null) {
                  return Text(
                    'Haven\'t received any SMS yet? Please request to resend.',
                    style: textColor,
                  );
                }
                return Text(
                  'The confirmation code was sent to ${widget._phoneNumber}. Code expires in ${time.min ?? 0}:${time.sec ?? 0} and then you can request to resend the code.',
                  style: textColor,
                );
              },
            ),
            SizedBox(height: 40),
            PinCodeTextField(
              controller: _smsCodeController,
              appContext: context,
              length: 6,
              onChanged: (value) {
                print(value);
              },
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(5),
                  fieldHeight: 50,
                  fieldWidth: 40,
                  activeFillColor:
                      isLightTheme(context) ? Colors.black : Colors.white,
                  selectedColor: kPrimary,
                  inactiveColor: Colors.grey,
                  activeColor: Colors.green),
              autoDisposeControllers: false,
              textStyle: textColor,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                UserCredential? userCredential =
                    await validateSmsCode(context, _smsCodeController.text);
                if (userCredential != null) {
                  print("User signed in: ${userCredential.user!.phoneNumber}");
                  await _connectSession();
                  Navigator.pop(context); // Navigate back to the previous page
                } else {
                  // Show an error message or handle the error
                }
              },
              child: Text("Submit", style: textColor),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 5.0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(45.0))),
            ),
            SizedBox(height: 30),
            !isResending
                ? TextButton(
                    child: Text(
                      'Resend Code',
                      style: TextStyle(
                          color: enableResend ? kPrimary : Colors.grey),
                    ),
                    onPressed: enableResend ? _resendCode : null,
                    style: ButtonStyle(
                      foregroundColor:
                          MaterialStateProperty.resolveWith<Color>((states) {
                        if (states.contains(MaterialState.disabled)) {
                          return Colors.grey;
                        } else {
                          return kPrimary;
                        }
                      }),
                      backgroundColor:
                          MaterialStateProperty.resolveWith<Color>((states) {
                        if (states.contains(MaterialState.disabled)) {
                          return Colors.grey.withOpacity(0.2);
                        } else {
                          return Colors.white;
                        }
                      }),
                      padding: MaterialStateProperty.all<EdgeInsets>(
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  )
                : CircularProgressIndicator(
                    color: kPrimary,
                  ),
          ],
        ),
      ),
    );
  }

  Future<String> _resendSmsCode(String phoneNumber) async {
    print('started resending');
    FirebaseAuth auth = FirebaseAuth.instance;
    Completer<String> completer = Completer<String>();

    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // This callback will be called if the verification is completed automatically (e.g. on Android devices)
      },
      verificationFailed: (FirebaseAuthException e) {
        print("Verification failed: ${e.message}");
        setState(() {});
      },
      codeSent: (String verificationId, int? resendToken) async {
        print("Code sent");
        widget._verificationId =
            verificationId; // Store the verificationId for future use
        completer.complete(widget._verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
    print('code resent');
    return completer.future;
  }

  Future<UserCredential?> validateSmsCode(
      BuildContext context, String smsCode) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget._verificationId!,
        smsCode: smsCode,
      );

      UserCredential userCredential =
          await auth.signInWithCredential(credential);
      print("User signed in: ${userCredential.user!.phoneNumber}");
      return userCredential;
    } catch (e) {
      print("Error validating SMS code: $e");
      return null;
    }
  }

  _connectSession() async {
    final firestore = FirebaseFirestore.instance;
    try {
      await firestore
          .collection('phone_numbers')
          .doc(widget._phoneNumber)
          .set({'phone_number': widget._phoneNumber});
    } catch (e) {
      print("Error storing phone number in Firestore: $e");
    }
    File? profileImage = context.read<ProfileImageCubit>().state;
    if (profileImage == null) {
      String assetPath = 'assets/avatar.png';
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/${assetPath.split('/').last}';
      final file = File(tempPath);
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      profileImage = file;
    }
    await context.read<OnboardingCubit>().connect(
        widget._username, profileImage!,
        phoneNumber: widget._phoneNumber);
  }

  void _resendCode() async {
    setState(() {
      secondsRemaining = expirationTime;
      enableResend = false;
      isResending = true;
      endTime = DateTime.now().millisecondsSinceEpoch + 1000 * expirationTime;
    });
    // Cancel the previous timer
    timer.cancel();

    // Create a new timer
    timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (secondsRemaining != 0) {
        setState(() {
          secondsRemaining--;
        });
      } else {
        setState(() {
          enableResend = true;
        });
      }
    });
    widget._verificationId = await _resendSmsCode(widget._phoneNumber);
    setState(() {
      isResending = false;
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}
