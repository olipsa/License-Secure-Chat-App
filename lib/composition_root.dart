import 'dart:io';

import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/data/datasource/datasource_contract.dart';
import 'package:flutter_chat_app/data/datasource/sqflite_datasource.dart';
import 'package:flutter_chat_app/data/factories/db_factory.dart';
import 'package:flutter_chat_app/data/services/image_uploader.dart';
import 'package:flutter_chat_app/states_management/home/chats_cubit.dart';
import 'package:flutter_chat_app/states_management/home/home_cubit.dart';
import 'package:flutter_chat_app/states_management/message/message_bloc.dart';
import 'package:flutter_chat_app/states_management/onboarding/onboarding_cubit.dart';
import 'package:flutter_chat_app/states_management/onboarding/profile_image_cubit.dart';
import 'package:flutter_chat_app/ui/pages/home/home.dart';
import 'package:flutter_chat_app/ui/pages/onboarding/onboarding.dart';
import 'package:flutter_chat_app/viewmodels/chats_view_model.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';
import 'package:sqflite/sqflite.dart';

class CompositionRoot {
  static late RethinkDb _r;
  static late Connection _connection;
  static late IUserService _userService;
  static late Database _db;
  static late IMessageService _messageService;
  static late IDataSource _datasource;

  static configure() async {
    _r = RethinkDb();
    _connection = await _r.connect(host: '172.23.0.1', port: 28015);
    _userService = UserService(r: _r, connection: _connection);
    _messageService = MessageService(_r, _connection);
    _db = await LocalDatabaseFactory().createDatabase();
    _datasource = SqfliteDatasource(_db);
    // _db.delete('chats');
    // _db.delete('messages');
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
    MessageBloc messageBloc = MessageBloc(_messageService);
    ChatsViewModel viewModel = ChatsViewModel(_datasource, _userService);
    ChatsCubit chatsCubit = ChatsCubit(viewModel);

    return MultiBlocProvider(providers: [
      BlocProvider(create: (BuildContext context) => homeCubit),
      BlocProvider(create: (BuildContext context) => messageBloc),
      BlocProvider(create: (BuildContext context) => chatsCubit)
    ], child: Home());
  }
}
