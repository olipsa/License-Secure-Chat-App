import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:flutter_chat_app/models/chat_model.dart';
import 'package:flutter_chat_app/states_management/home/chats_cubit.dart';
import 'package:flutter_chat_app/states_management/message/message_bloc.dart';
import 'package:flutter_chat_app/states_management/typing/typing_notification_bloc.dart';
import 'package:flutter_chat_app/theme.dart';
import 'package:flutter_chat_app/ui/pages/home/home_router.dart';
import 'package:flutter_chat_app/ui/widgets/home/profile_image.dart';
import 'package:flutter_chat_app/ui/widgets/shared/header_status.dart';
import 'package:intl/intl.dart';

class Chats extends StatefulWidget {
  final User user;
  final IHomeRouter router;
  const Chats(this.user, this.router, {super.key});

  @override
  State<Chats> createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  var chats = [];
  final typingEvents = [];
  @override
  void initState() {
    super.initState();
    _updateChatsOnMessageReceived();
    context.read<ChatsCubit>().chats();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatsCubit, List<Chat>>(builder: (__, chats) {
      this.chats = chats;
      if (this.chats.isEmpty) return Container();
      context.read<TypingNotificationBloc>().add(
          TypingNotificationEvent.onSubscribed(widget.user,
              usersWithChat: chats.map((e) => e.from.id).toList()));
      return _buildListView();
    });
  }

  _buildListView() {
    return ListView.separated(
        padding: const EdgeInsets.only(top: 15.0, right: 16.0),
        itemBuilder: (_, index) => GestureDetector(
              child: _chatItem(chats[index]),
              onTap: () async {
                await widget.router.onShowMessageThread(
                    context, chats[index].from, widget.user);

                await context
                    .read<ChatsCubit>()
                    .chats(); // update unread message count
              },
            ),
        separatorBuilder: (_, __) => const Divider(),
        itemCount: chats.length);
  }

  _chatItem(Chat chat) => ListTile(
        contentPadding: const EdgeInsets.only(left: 16.0),
        leading: ProfileImage(
            imageUrl: chat.from.photoUrl,
            online: chat.from.active,
            username: chat.from.username,
            phoneNumber: chat.from.phoneNumber),
        title: Text(chat.from.username,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isLightTheme(context) ? Colors.black : Colors.white)),
        subtitle: BlocBuilder<TypingNotificationBloc, TypingNotificationState>(
            builder: (__, state) {
          if (state is TypingNotificationReceivedSuccess &&
              state.event.event == Typing.start &&
              state.event.from == chat.from.id) {
            typingEvents.add(state.event.from);
          }

          if (state is TypingNotificationReceivedSuccess &&
              state.event.event == Typing.stop &&
              state.event.from == chat.from.id) {
            typingEvents.remove(state.event.from);
          }

          if (typingEvents.contains(chat.from.id)) {
            return Text(
              'typing...',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            );
          }

          return Text(
              chat.mostRecent!.message.contentType == ContentType.text
                  ? chat.mostRecent!.message.contents['text']
                  : chat.mostRecent!.message.from == widget.user.id
                      ? 'You sent a photo'
                      : '${chat.from.username} sent a photo',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color:
                      isLightTheme(context) ? Colors.black54 : Colors.white70,
                  fontWeight:
                      chat.unread > 0 ? FontWeight.bold : FontWeight.normal));
        }),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateTime.now().day == chat.mostRecent!.message.timestamp.day
                  ? DateFormat('h:mm a')
                      .format(chat.mostRecent!.message.timestamp)
                  : formatDate(chat.mostRecent!.message.timestamp)
                      .split(',')
                      .first,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color:
                        isLightTheme(context) ? Colors.black54 : Colors.white70,
                  ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50.0),
                child: chat.unread > 0
                    ? Container(
                        height: 15.0,
                        width: 15.0,
                        color: kPrimary,
                        alignment: Alignment.center,
                        child: Text(
                          chat.unread.toString(),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            )
          ],
        ),
      );

  _updateChatsOnMessageReceived() {
    final chatsCubit = context.read<ChatsCubit>();
    context.read<MessageBloc>().stream.listen((state) async {
      if (state is MessageReceivedSuccess) {
        // creates a new chat or adds message to existing chat
        await chatsCubit.viewModel.receivedMessage(state.message);
        chatsCubit.chats();
      }
    });
  }
}
