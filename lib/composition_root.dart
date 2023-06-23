import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/cache/local_cache.dart';
import 'package:flutter_chat_app/data/datasource/datasource_contract.dart';
import 'package:flutter_chat_app/data/datasource/sqflite_datasource.dart';
import 'package:flutter_chat_app/data/factories/db_factory.dart';
import 'package:flutter_chat_app/data/services/image_uploader.dart';
import 'package:flutter_chat_app/data/services/local_encryption_service.dart';
import 'package:flutter_chat_app/models/encrypted_user.dart';
import 'package:flutter_chat_app/states_management/home/chats_cubit.dart';
import 'package:flutter_chat_app/states_management/home/home_cubit.dart';
import 'package:flutter_chat_app/states_management/message/message_bloc.dart';
import 'package:flutter_chat_app/states_management/message_thread/message_thread_cubit.dart';
import 'package:flutter_chat_app/states_management/onboarding/onboarding_cubit.dart';
import 'package:flutter_chat_app/states_management/onboarding/profile_image_cubit.dart';
import 'package:flutter_chat_app/states_management/receipt/receipt_bloc.dart';
import 'package:flutter_chat_app/states_management/typing/typing_notification_bloc.dart';
import 'package:flutter_chat_app/ui/pages/home/home.dart';
import 'package:flutter_chat_app/ui/pages/home/home_router.dart';
import 'package:flutter_chat_app/ui/pages/message_thread/message_thread.dart';
import 'package:flutter_chat_app/ui/pages/message_thread/message_thread_router.dart';
import 'package:flutter_chat_app/ui/pages/onboarding/onboarding.dart';
import 'package:flutter_chat_app/ui/pages/onboarding/onboarding_router.dart';
import 'package:flutter_chat_app/ui/pages/camera/send_picture.dart';
import 'package:flutter_chat_app/viewmodels/chat_view_model.dart';
import 'package:flutter_chat_app/viewmodels/chats_view_model.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class CompositionRoot {
  static late RethinkDb _r;
  static late Connection _connection;
  static late IUserService _userService;
  static late Database _db;
  static late IMessageService _messageService;
  static late IDataSource _datasource;
  static late ILocalCache _localCache;
  static late MessageBloc _messageBloc;
  static late ITypingNotification _typingNotification;
  static late TypingNotificationBloc _typingNotificationBloc;
  static late ChatsCubit _chatsCubit;
  static late EncryptedUser _encryptedUser;
  static late IRemoteEncryptionService _remoteEncryptionService;
  static late LocalEncryptionService _localEncryptionService;

  static configure() async {
    _r = RethinkDb();
    _connection = await _r.connect(host: '192.168.1.31', port: 28015);
    _userService = UserService(r: _r, connection: _connection);
    _messageService = MessageService(_r, _connection);
    _typingNotification = TypingNotification(_r, _connection, _userService);
    _db = await LocalDatabaseFactory().createDatabase();
    _datasource = SqfliteDatasource(_db);
    final sharedPref = await SharedPreferences.getInstance();
    _localCache = LocalCache(sharedPref);
    _encryptedUser = EncryptedUser();
    _remoteEncryptionService = RemoteEncryptionService(_r, _connection);
    _localEncryptionService =
        LocalEncryptionService(_remoteEncryptionService, _encryptedUser);
    _messageBloc = MessageBloc(_messageService, _localEncryptionService);
    _typingNotificationBloc = TypingNotificationBloc(_typingNotification);
    final viewModel = ChatsViewModel(
      _datasource,
      _userService,
    );
    _chatsCubit = ChatsCubit(viewModel);
    _db.delete('chats');
    _db.delete('messages');
  }

  static Widget start() {
    _localCache.remove('USER');
    final user = _localCache.fetch('USER');
    return user.isEmpty
        ? composeOnboardingUi()
        : composeHomeUi(User.fromJson(user));
  }

  static Widget composeOnboardingUi() {
    ImageUploader imageUploader =
        ImageUploader('http://192.168.1.31:3000/upload');
    OnboardingCubit onboardingCubit = OnboardingCubit(_userService,
        imageUploader, _localCache, _remoteEncryptionService, _encryptedUser);
    ProfileImageCubit imageCubit = ProfileImageCubit();
    IOnboardingRouter router = OnboardingRouter(composeHomeUi);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (BuildContext context) => onboardingCubit),
        BlocProvider(create: (BuildContext context) => imageCubit)
      ],
      child: Onboarding(router),
    );
  }

  static Widget composeHomeUi(User me) {
    HomeCubit homeCubit = HomeCubit(_userService, _localCache);
    IHomeRouter router = HomeRouter(showMessageThread: composeMessageThreadUi);

    return MultiBlocProvider(providers: [
      BlocProvider(create: (BuildContext context) => homeCubit),
      BlocProvider(create: (BuildContext context) => _messageBloc),
      BlocProvider(create: (BuildContext context) => _typingNotificationBloc),
      BlocProvider(create: (BuildContext context) => _chatsCubit)
    ], child: Home(me, router, _userService));
  }

  static Widget composeMessageThreadUi(User receiver, User me) {
    ChatViewModel viewModel = ChatViewModel(_datasource);
    MessageThreadCubit messageThreadCubit = MessageThreadCubit(viewModel);
    IReceiptService receiptService = ReceiptService(_r, _connection);
    ReceiptBloc receiptBloc = ReceiptBloc(receiptService);
    IMessageThreadRouter router = MessageThreadRouter(
        showMessageThread: composeMessageThreadUi,
        showPicturePreview: composePicturePreviewUi);

    return MultiBlocProvider(
        providers: [
          BlocProvider(create: (BuildContext context) => messageThreadCubit),
          BlocProvider(create: (BuildContext context) => receiptBloc)
        ],
        child: MessageThread(receiver, me, _messageBloc, _chatsCubit,
            _typingNotificationBloc, router));
  }

  static Widget composePicturePreviewUi(
      User receiver, User me, String? imagePath,
      {String? chatId}) {
    ChatViewModel viewModel = ChatViewModel(_datasource);
    MessageThreadCubit messageThreadCubit = MessageThreadCubit(viewModel);

    IMessageThreadRouter router = MessageThreadRouter(
        showMessageThread: composeMessageThreadUi,
        showPicturePreview: composePicturePreviewUi);

    return MultiBlocProvider(
        providers: [
          BlocProvider(create: (BuildContext context) => messageThreadCubit)
        ],
        child: SendPicture(
            imagePath!, me, receiver, _messageBloc, router, chatId));
  }
}
