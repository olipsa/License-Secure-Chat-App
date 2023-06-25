// ignore_for_file: avoid_print

import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:flutter_chat_app/states_management/home/chats_cubit.dart';
import 'package:flutter_chat_app/states_management/home/home_cubit.dart';
import 'package:flutter_chat_app/states_management/home/home_state.dart';
import 'package:flutter_chat_app/states_management/message/message_bloc.dart';
import 'package:flutter_chat_app/theme.dart';
import 'package:flutter_chat_app/ui/pages/home/home_router.dart';
import 'package:flutter_chat_app/ui/widgets/home/active/active_users.dart';
import 'package:flutter_chat_app/ui/widgets/home/chats/chats.dart';
import 'package:flutter_chat_app/ui/widgets/home/passphrase_display.dart';
import 'package:flutter_chat_app/ui/widgets/home/qr/qr_code.dart';
import 'package:flutter_chat_app/ui/widgets/shared/header_status.dart';
import 'package:local_auth/local_auth.dart';

class Home extends StatefulWidget {
  final User me;
  final IHomeRouter router;
  final IUserService userService;
  const Home(this.me, this.router, this.userService, {super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late User _user;
  late IUserService _userService;
  final LocalAuthentication _localAuthentication = LocalAuthentication();

  @override
  void initState() {
    //_biometricAuth();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _user = widget.me;
    _userService = widget.userService;
    _initialSetup();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    TextStyle textColor = isLightTheme(context)
        ? TextStyle(color: Colors.black)
        : TextStyle(color: Colors.white);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: HeaderStatus(
              _user.username, _user.photoUrl, true, _user.phoneNumber),
          actions: [
            PopupMenuButton<String>(
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'option1',
                  child: Text(
                    'Add phone number',
                    style: textColor,
                  ),
                ),
                PopupMenuItem(
                  value: 'option2',
                  child: Text(
                    'View security passphrase',
                    style: textColor,
                  ),
                ),
                PopupMenuItem(
                  value: 'option3',
                  child: Text(
                    'Delete account',
                    style: textColor,
                  ),
                ),
              ],
              icon: const Icon(
                Icons.settings_outlined,
                color: kPrimary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5), // Add rounded corners
                side: BorderSide.none,
              ),
              offset: const Offset(0, 40),
              color: isLightTheme(context)
                  ? Color.fromARGB(255, 233, 232, 232)
                  : kActiveUsersDark,
              onSelected: (value) {
                // Handle the selected option here
                print('Selected option: $value');
                if (value == 'option2') {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PassphraseWidget(
                              passphrase: widget.me.passphrase!)));
                } else if (value == 'option3') {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Delete account',
                            style: isLightTheme(context)
                                ? TextStyle(color: Colors.black)
                                : TextStyle(color: Colors.white)),
                        content: Text(
                            'Are you sure you want to delete your account? This action is irreversible.',
                            style: isLightTheme(context)
                                ? TextStyle(color: Colors.black)
                                : TextStyle(color: Colors.white)),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: Text('No'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Handle account deletion here
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: Text(
                              'Yes, delete account',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            )
          ],
          bottom: TabBar(
            indicatorPadding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
            tabs: [
              Tab(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Align(
                    alignment: Alignment.center,
                    child: Text('Messages'),
                  ),
                ),
              ),
              Tab(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: BlocBuilder<HomeCubit, HomeState>(
                        builder: (_, state) => state is HomeSuccess
                            ? Text('Contacts(${state.onlineUsers.length})')
                            : const Text('Contacts(0)')),
                  ),
                ),
              )
            ],
          ),
        ),
        body: Stack(children: [
          TabBarView(children: [
            Chats(_user, widget.router),
            ActiveUsers(widget.router, _user),
          ]),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: () {
                // open the QR code page of the user
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => QrCode(
                              me: _user,
                              userService: _userService,
                              router: widget.router,
                            )));
              },
              backgroundColor: kPrimary,
              child: const Icon(
                Icons.qr_code,
                color: kBubbleDark,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  _initialSetup() async {
    // if user disconnected from the phone
    final user =
        (!_user.active) ? await context.read<HomeCubit>().connect() : _user;

    await context.read<ChatsCubit>().chats();
    await context.read<HomeCubit>().activeUsers(user);
    context.read<MessageBloc>().add(MessageEvent.onSubscribed(_user));
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        // in the foreground; responding to user
        print('App resumed');
        _user.lastseen = DateTime.now();
        _user.active = true;
        await _userService.connect(_user);
        break;
      case AppLifecycleState.paused:
        // app minimized; not visible, no response, in the background
        print('App paused');
        _user.lastseen = DateTime.now();
        _user.active = false;
        await _userService.update(_user);
        break;
      case AppLifecycleState.inactive:
        // in foreground, no response / in split screen view
        print('App inactive');
        break;
      case AppLifecycleState.detached:
        // not visible / being created or destroyed
        print('App detached');
        break;
      default:
        break;
    }
  }

  _biometricAuth() async {
    bool isAvailable = await _isBiometricAvailable();
    if (isAvailable) {
      bool isAuthenticated = await _authenticate();
      if (isAuthenticated) {
        // Navigate to another screen or perform a secure action
      } else {
        print('Authentication failed');
      }
    } else {
      print('Biometric authentication is not available');
    }
  }

  Future<bool> _isBiometricAvailable() async {
    bool isAvailable = await _localAuthentication.canCheckBiometrics;
    return isAvailable;
  }

  Future<bool> _authenticate() async {
    bool isAuthenticated = await _localAuthentication.authenticate(
      localizedReason: 'Please authenticate to proceed.',
    );
    return isAuthenticated;
  }
}
