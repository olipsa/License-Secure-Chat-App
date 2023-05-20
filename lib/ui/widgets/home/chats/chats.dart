import 'package:flutter/material.dart';
import 'package:flutter_chat_app/colors.dart';
import 'package:flutter_chat_app/theme.dart';
import 'package:flutter_chat_app/ui/widgets/home/profile_image.dart';

class Chats extends StatefulWidget {
  const Chats();

  @override
  State<Chats> createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        padding: EdgeInsets.only(top: 15.0, right: 16.0),
        itemBuilder: (_, index) => _chatItem(),
        separatorBuilder: (_, __) => Divider(),
        itemCount: 3);
  }

  _chatItem() => ListTile(
        contentPadding: EdgeInsets.only(left: 16.0),
        leading: ProfileImage(
            imageUrl:
                "https://wallpapers.com/images/featured-full/cool-profile-picture-swtwohfekfqtvt1s.jpg",
            online: true),
        title: Text('User',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isLightTheme(context) ? Colors.black : Colors.white)),
        subtitle: Text('Thanks',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color:
                    isLightTheme(context) ? Colors.black54 : Colors.white70)),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '12pm',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color:
                        isLightTheme(context) ? Colors.black54 : Colors.white70,
                  ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50.0),
                child: Container(
                  height: 15.0,
                  width: 15.0,
                  color: kPrimary,
                  alignment: Alignment.center,
                  child: Text(
                    '2',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
            )
          ],
        ),
      );
}
