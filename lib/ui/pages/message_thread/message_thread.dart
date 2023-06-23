// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:flutter_chat_app/models/local_message.dart';

import 'package:flutter_chat_app/states_management/home/chats_cubit.dart';
import 'package:flutter_chat_app/states_management/message/message_bloc.dart';
import 'package:flutter_chat_app/states_management/message_thread/message_thread_cubit.dart';
import 'package:flutter_chat_app/states_management/receipt/receipt_bloc.dart';
import 'package:flutter_chat_app/states_management/typing/typing_notification_bloc.dart';
import 'package:flutter_chat_app/theme.dart';
import 'package:flutter_chat_app/ui/pages/camera/camera_screen.dart';
import 'package:flutter_chat_app/ui/pages/message_thread/message_thread_router.dart';
import 'package:flutter_chat_app/ui/widgets/message_thread/receiver_message.dart';
import 'package:flutter_chat_app/ui/widgets/message_thread/sender_message.dart';
import 'package:flutter_chat_app/ui/widgets/shared/header_status.dart';

class MessageThread extends StatefulWidget {
  final User receiver;
  final User me;
  final MessageBloc messageBloc;
  final TypingNotificationBloc typingNotificationBloc;
  final ChatsCubit chatsCubit;
  final IMessageThreadRouter router;
  const MessageThread(
    this.receiver,
    this.me,
    this.messageBloc,
    this.chatsCubit,
    this.typingNotificationBloc,
    this.router, {
    super.key,
  });

  @override
  State<MessageThread> createState() => _MessageThreadState();
}

class _MessageThreadState extends State<MessageThread> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textEditingController = TextEditingController();
  String? chatId = '';
  late User receiver;
  late StreamSubscription _subscription;
  List<LocalMessage> messages = [];
  Timer? _startTypingTimer;
  Timer? _stopTypingTimer;

  @override
  void initState() {
    super.initState();
    chatId = widget.receiver.id;
    receiver = widget.receiver;
    _updateOnMessageReceived();
    _updateOnReceiptReceived();
    context.read<ReceiptBloc>().add(ReceiptEvent.onSubscribed(widget.me));
    widget.typingNotificationBloc.add(TypingNotificationEvent.onSubscribed(
        widget.me,
        usersWithChat: [receiver.id]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isLightTheme(context) ? Colors.black : Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
          Expanded(
              child:
                  BlocBuilder<TypingNotificationBloc, TypingNotificationState>(
            bloc: widget.typingNotificationBloc,
            builder: (_, state) {
              bool? typing;
              if (state is TypingNotificationReceivedSuccess &&
                  state.event.event == Typing.start &&
                  state.event.from == receiver.id) {
                typing = true;
              }
              return HeaderStatus(
                receiver.username,
                receiver.photoUrl,
                receiver.active,
                receiver.phoneNumber,
                lastSeen: receiver.lastseen,
                typing: typing,
              );
            },
          ))
        ]),
      ),
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Column(
          children: [
            Flexible(
              flex: 6,
              child: BlocBuilder<MessageThreadCubit, List<LocalMessage>>(
                  builder: (__, messages) {
                this.messages = messages;
                if (this.messages.isEmpty) {
                  return Container(
                    color: Colors.transparent,
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) =>
                    _scrollToTheEnd()); // runs the method when the list view is rendered
                return _buildListOfMessages();
              }),
            ),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                    color: isLightTheme(context) ? Colors.white : kAppBarDark,
                    boxShadow: const [
                      BoxShadow(
                          offset: Offset(0, -3),
                          blurRadius: 6.0,
                          color: Colors.black12)
                    ]),
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _buildMessageInput(context)),
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Row(
                          children: [
                            SizedBox(
                              // send image/video container
                              height: 45.0,
                              width: 45.0,
                              child: RawMaterialButton(
                                fillColor: kPrimary,
                                shape: const CircleBorder(),
                                elevation: 5.0,
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  _openCamera();
                                  // Handle camera button press
                                },
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            SizedBox(
                              // send button container
                              height: 45.0,
                              width: 45.0,
                              child: RawMaterialButton(
                                fillColor: kPrimary,
                                shape: const CircleBorder(),
                                elevation: 5.0,
                                child: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  _sendMessage();
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  _buildListOfMessages() => ListView.builder(
        padding: const EdgeInsets.only(top: 16, left: 16.0, bottom: 20),
        itemBuilder: (__, idx) {
          if (messages[idx].message.from == receiver.id) {
            _sendReceipt(messages[idx]);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ReceiverMessage(
                  messages[idx], receiver.photoUrl, receiver.username),
            );
          } else {
            //message from sender
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SenderMessage(messages[idx]),
            );
          }
        },
        itemCount: messages.length,
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        addAutomaticKeepAlives: true,
      );

  _buildMessageInput(BuildContext context) {
    final border = OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(90.0)),
        borderSide: isLightTheme(context)
            ? BorderSide.none
            : BorderSide(color: Colors.grey.withOpacity(0.3)));
    return Focus(
      onFocusChange: (focus) {
        // stop typing
        if (_startTypingTimer == null || (_startTypingTimer != null && focus)) {
          return;
        }
        _stopTypingTimer?.cancel();
        _dispatchTyping(Typing.stop);
      },
      child: TextFormField(
        controller: _textEditingController,
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        style: Theme.of(context).textTheme.bodySmall,
        cursorColor: kPrimary,
        onChanged: _sendTypingNotification,
        decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
            enabledBorder: border,
            filled: true,
            fillColor:
                isLightTheme(context) ? kPrimary.withOpacity(0.1) : kBubbleDark,
            focusedBorder: border),
      ),
    );
  }

  void _updateOnMessageReceived() {
    final messageThreadCubit = context.read<MessageThreadCubit>();
    if (chatId!.isNotEmpty) messageThreadCubit.messages(chatId);
    _subscription = widget.messageBloc.stream.listen((state) async {
      if (state is MessageReceivedSuccess) {
        //write the message to the db
        await messageThreadCubit.viewModel.receivedMessage(state.message);
        final receipt = Receipt(
            recipient: state.message.from,
            messageId: state.message.id,
            status: ReceiptStatus.read,
            timestamp: DateTime.now());
        context.read<ReceiptBloc>().add(ReceiptEvent.onMessageSent(receipt));
      }
      if (state is MessageSentSuccess) {
        await messageThreadCubit.viewModel.sentMessage(state.message);
      }
      if (chatId!.isEmpty) chatId = messageThreadCubit.viewModel.chatId;
      messageThreadCubit.messages(chatId);
    });
  }

  void _updateOnReceiptReceived() {
    final messageThreadCubit = context.read<MessageThreadCubit>();
    context.read<ReceiptBloc>().stream.listen((state) async {
      if (state is ReceiptReceivedSuccess) {
        // update the receipt on the local db
        await messageThreadCubit.viewModel.updateMessageReceipt(state.receipt);
        messageThreadCubit.messages(chatId);
        //update chats on the previous screen
        widget.chatsCubit.chats();
      }
    });
  }

  _sendMessage() {
    if (_textEditingController.text.trim().isEmpty) return;

    final message = Message(
        from: widget.me.id,
        to: receiver.id,
        timestamp: DateTime.now(),
        contents: _textEditingController.text,
        contentType: ContentType.text);
    final sendMessageEvent = MessageEvent.onMessageSent(message);
    widget.messageBloc.add(sendMessageEvent);

    _textEditingController.clear();
    _startTypingTimer?.cancel();
    _stopTypingTimer?.cancel();

    _dispatchTyping(Typing.stop);
  }

  void _dispatchTyping(Typing event) {
    // creates the typing event and send it
    final typing =
        TypingEvent(from: widget.me.id, to: receiver.id, event: event);
    widget.typingNotificationBloc
        .add(TypingNotificationEvent.onTypingEventSent(typing));
  }

  void _openCamera() async {
    final cameras = await availableCameras(); // Get the available cameras
    final camera = cameras.first; // Select the first available camera

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              CameraScreen(camera, widget.me, receiver, widget.router)),
    );
  }

  void _sendTypingNotification(String text) {
    if (text.trim().isEmpty || messages.isEmpty) return;
    if (_startTypingTimer?.isActive ?? false) return;
    if (_stopTypingTimer?.isActive ?? false) _stopTypingTimer?.cancel();
    _dispatchTyping(Typing.start);
    _startTypingTimer = Timer(const Duration(seconds: 5), () {});
    // after 1s of sending the typing notification, the typing message will stop
    _stopTypingTimer =
        Timer(const Duration(seconds: 6), () => _dispatchTyping(Typing.stop));
  }

  _scrollToTheEnd() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
  }

  _sendReceipt(LocalMessage message) async {
    // updates the local db with the correct state of the message
    if (message.receipt == ReceiptStatus.read) return;
    final receipt = Receipt(
        recipient: message.message.from,
        messageId: message.id,
        status: ReceiptStatus.read,
        timestamp: DateTime.now());
    context.read<ReceiptBloc>().add(ReceiptEvent.onMessageSent(receipt));
    await context
        .read<MessageThreadCubit>()
        .viewModel
        .updateMessageReceipt(receipt);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _subscription.cancel();
    _stopTypingTimer?.cancel();
    _startTypingTimer?.cancel();
    super.dispose();
  }
}
