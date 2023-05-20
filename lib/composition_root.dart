import 'dart:io';

import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/data/services/image_uploader.dart';
import 'package:flutter_chat_app/states_management/home/home_cubit.dart';
import 'package:flutter_chat_app/states_management/onboarding/onboarding_cubit.dart';
import 'package:flutter_chat_app/states_management/onboarding/profile_image_cubit.dart';
import 'package:flutter_chat_app/ui/pages/home/home.dart';
import 'package:flutter_chat_app/ui/pages/onboarding/onboarding.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

class CompositionRoot {
  static late RethinkDb _r;
  static late Connection _connection;
  static late IUserService _userService;

  static configure() async {
    _r = RethinkDb();
    _connection = await _r.connect(host: '172.23.0.1', port: 28015);
    _userService = UserService(r: _r, connection: _connection);
  }

  static Widget composeOnboardingUi() {
    ImageUploader imageUploader =
        ImageUploader('http://172.23.0.1:3000/upload');
    OnboardingCubit onboardingCubit =
        OnboardingCubit(_userService, imageUploader);
    ProfileImageCubit imageCubit = ProfileImageCubit();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (BuildContext context) => onboardingCubit),
        BlocProvider(create: (BuildContext context) => imageCubit)
      ],
      child: const Onboarding(),
    );
  }

  static Widget composeHomeUi() {
    HomeCubit homeCubit = HomeCubit(_userService);

    return MultiBlocProvider(
        providers: [BlocProvider(create: (BuildContext context) => homeCubit)],
        child: Home());
  }
}
