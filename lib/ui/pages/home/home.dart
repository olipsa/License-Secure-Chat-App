import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/states_management/home/chats_cubit.dart';
import 'package:flutter_chat_app/states_management/home/home_cubit.dart';
import 'package:flutter_chat_app/states_management/home/home_state.dart';
import 'package:flutter_chat_app/states_management/message/message_bloc.dart';
import 'package:flutter_chat_app/ui/pages/home/home_router.dart';
import 'package:flutter_chat_app/ui/widgets/home/active/active_users.dart';
import 'package:flutter_chat_app/ui/widgets/home/chats/chats.dart';
import 'package:flutter_chat_app/ui/widgets/shared/header_status.dart';

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
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _user = widget.me;
    _userService = widget.userService;
    _initialSetup();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: HeaderStatus(_user.username, _user.photoUrl, true),
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
                            ? Text('Active(${state.onlineUsers.length})')
                            : const Text('Active(0)')),
                  ),
                ),
              )
            ],
          ),
        ),
        body: TabBarView(children: [
          Chats(_user, widget.router),
          ActiveUsers(widget.router, _user),
        ]),
      ),
    );
  }

  _initialSetup() async {
    // if user disconnected from the phone
    final user =
        (!_user.active) ? await context.read<HomeCubit>().connect() : _user;

    context.read<ChatsCubit>().chats();
    context.read<HomeCubit>().activeUsers(user);
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
}
