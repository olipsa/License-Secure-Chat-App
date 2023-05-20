import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/states_management/home/home_cubit.dart';
import 'package:flutter_chat_app/states_management/home/home_state.dart';
import 'package:flutter_chat_app/ui/widgets/home/profile_image.dart';

class ActiveUsers extends StatefulWidget {
  const ActiveUsers();

  @override
  State<ActiveUsers> createState() => _ActiveUsersState();
}

class _ActiveUsersState extends State<ActiveUsers> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(builder: (_, state) {
      if (state is HomeLoading)
        return Center(child: CircularProgressIndicator());
      if (state is HomeSuccess) return _buildLists(state.onlineUsers);
      return Container();
    });
  }

  _listItem(User user) => ListTile(
        leading: ProfileImage(
          imageUrl: user.photoUrl,
          online: true,
        ),
        title: Text(
          user.username,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontSize: 14.0, fontWeight: FontWeight.bold),
        ),
      );
  _buildLists(List<User> users) => ListView.separated(
      padding: EdgeInsets.only(top: 15.0, right: 16.0),
      itemBuilder: (BuildContext context, index) => _listItem(users[index]),
      separatorBuilder: (_, __) => Divider(),
      itemCount: users.length);
}