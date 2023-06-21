// ignore_for_file: use_build_context_synchronously

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
import 'package:flutter_chat_app/ui/pages/onboarding/enter_sms_code.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:path_provider/path_provider.dart';

class PhoneAuth extends StatefulWidget {
  final String username;
  const PhoneAuth(this.username, {super.key});

  @override
  PhoneAuthState createState() => PhoneAuthState();
}

class PhoneAuthState extends State<PhoneAuth> {
  PhoneNumber? _phoneNumber;
  bool isValid = true;
  String _phoneError = '';
  String? _verificationId;
  final String _initialCountryCode = 'RO';
  late Country _country;
  bool isResending = false;

  @override
  Widget build(BuildContext context) {
    _country =
        countries.firstWhere((element) => element.code == _initialCountryCode);
    TextStyle textColor = isLightTheme(context)
        ? const TextStyle(color: Colors.black)
        : const TextStyle(color: Colors.white);
    return Scaffold(
      appBar: AppBar(title: const Text("Add your phone number")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text(
                    'Secure Messenger will need to verify your account. You will receive a SMS with the verification code.',
                    style: textColor,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20.0),
                  IntlPhoneField(
                    dropdownTextStyle: textColor,
                    cursorColor: kPrimary,
                    pickerDialogStyle: PickerDialogStyle(
                      countryCodeStyle: textColor,
                      countryNameStyle: textColor,
                      searchFieldCursorColor: kPrimary,
                    ),
                    initialCountryCode: 'RO',
                    dropdownIcon: const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: kPrimary,
                    ),
                    style: textColor,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.only(
                          left: 30.0, right: 30.0, bottom: 16.0),
                      labelText: 'Phone Number',
                      floatingLabelStyle: const TextStyle(color: kPrimary),
                      hintText: 'Enter your phone number',
                      errorText: _phoneError.isEmpty ? null : _phoneError,
                    ),
                    onChanged: (phone) {
                      _phoneNumber = phone;
                      final numericRegex = RegExp(r'^[0-9]+$');
                      if (!numericRegex.hasMatch(_phoneNumber!.number)) {
                        setState(() {
                          _phoneError = 'Invalid phone number';
                        });
                      } else {
                        setState(() {
                          _phoneError = '';
                        });
                      }
                    },
                    onCountryChanged: (country) => country = country,
                  ),
                  const SizedBox(height: 10.0),
                  !isResending
                      ? ElevatedButton(
                          onPressed: () async {
                            // send a verification code if the phone number is correct
                            if (await _isValidPhone()) {
                              String verificationId = await _sendSmsCode(
                                  _phoneNumber!.completeNumber);
                              // phone number provided has the correct format; route to phone verification page
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
                                      BlocProvider.value(
                                          value: onboardingCubit),
                                    ],
                                    child: EnterSmsCodePage(
                                        _phoneNumber!.completeNumber,
                                        verificationId,
                                        widget.username),
                                  ),
                                ),
                              );
                            } else {
                              setState(() {});
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              elevation: 5.0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(45.0))),
                          child: IntrinsicWidth(
                            child: Container(
                              height: 45.0,
                              alignment: Alignment.center,
                              child: Text(
                                'Send Verification Code',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                        fontSize: 13.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                              ),
                            ),
                          ))
                      : CircularProgressIndicator(
                          color: kPrimary,
                        ),
                  const SizedBox(height: 20.0),
                  Text(
                    'Your carrier may charge for SMS messages',
                    style: TextStyle(
                        fontSize: 12.0,
                        color: isLightTheme(context)
                            ? Colors.black
                            : Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ])),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  _connectSession();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(45.0))),
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18.0,
                ),
                label: Text(
                  'Skip',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 13.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 5.0),
            const Text(
              'You can add your phone number later. Until then, you will not be discoverable for your contacts.',
              style: TextStyle(fontSize: 12.0, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _isValidPhone() async {
    if (_phoneNumber == null) return false;
    if (_phoneError != '') return false;
    print(_country.minLength);
    print(_country.maxLength);
    print(_country.code);
    if (_phoneNumber!.number.length < _country.minLength ||
        _phoneNumber!.number.length > _country.maxLength) {
      return false;
    }
    if (await _isPhoneNumberRegistered()) {
      _phoneError = 'This phone number is already registered.';
      return false;
    }
    return true;
  }

  Future<bool> _isPhoneNumberRegistered() async {
    final firestore = FirebaseFirestore.instance;
    DocumentSnapshot snapshot;
    try {
      snapshot = await firestore
          .collection('phone_numbers')
          .doc(_phoneNumber!.completeNumber)
          .get();
    } catch (e) {
      print("Error retrieving phone number document: $e");
      // Handle the error and retry logic here, such as waiting for the network connection to be available again.
      return false;
    }

    return snapshot.exists;
  }

  Future<String> _sendSmsCode(String phoneNumber) async {
    setState(() {
      isResending = true;
    });
    FirebaseAuth auth = FirebaseAuth.instance;
    Completer<String> completer = Completer<String>();

    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // This callback will be called if the verification is completed automatically (e.g. on Android devices)
      },
      verificationFailed: (FirebaseAuthException e) {
        print("Verification failed: ${e.message}");
        _phoneError = "Verification failed.";
        setState(() {});
      },
      codeSent: (String verificationId, int? resendToken) async {
        print("Code sent");
        _verificationId =
            verificationId; // Store the verificationId for future use
        completer.complete(_verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
    setState(() {
      isResending = false;
    });
    return completer.future;
  }

  _connectSession() async {
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
    await context
        .read<OnboardingCubit>()
        .connect(widget.username, profileImage);
  }
}
