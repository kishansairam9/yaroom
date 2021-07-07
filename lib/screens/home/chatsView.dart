import 'package:flutter/material.dart';
import 'package:faker/faker.dart';
import 'dart:math';
import 'chatPage.dart';

class ChatView extends StatefulWidget {
  final _chats = <ProfileTile>[];

  get tiles => _chats;

  ChatView() {
    for (int i = 0; i < 30; i++) {
      _chats.add(ProfileTile());
    }
  }

  @override
  ChatViewState createState() => ChatViewState();
}

class ChatViewState extends State<ChatView> {
  @override
  Widget build(BuildContext context) {
    // return ListView(
    //   children: widget._chats,
    // );
    return ListView(
        children: ListTile.divideTiles(
      context: context,
      tiles: widget._chats,
    ).toList());
  }
}

class ProfileTile extends StatefulWidget {
  late final _image;
  late final String _name;

  get image => _image;
  get name => _name;

  ProfileTile() {
    _image = faker.image.image(
        width: 150, height: 150, keywords: ['people', 'nature'], random: true);
    _name = faker.person.name();
  }

  @override
  ProfileTileState createState() => ProfileTileState();
}

class ProfileTileState extends State<ProfileTile> {
  int _unread = 0;
  String _lastChat = '';

  ProfileTileState() {
    _unread = Random().nextInt(20);
  }

  void _showChat() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      return ChatPage(name: widget.name, image: widget.image);
    }));
  }

  @override
  Widget build(BuildContext context) {
    // return Card(
    return ListTile(
      minVerticalPadding: 25.0,
      onTap: _showChat,
      leading: CircleAvatar(
        backgroundColor: Colors.grey[350],
        foregroundImage: NetworkImage('${widget.image}'),
        backgroundImage: AssetImage('assets/no-profile.png'),
        radius: 28.0,
      ),
      title: Text(widget.name),
      subtitle: _lastChat.isEmpty ? null : Text(_lastChat),
      trailing: _unread > 0
          ?
          // TODO: Badges float around when puled from bottom to top agressively, should animate even slightly
          MaterialButton(
              onPressed: () {},
              color: Colors.blueGrey[400],
              child: Text(
                '$_unread',
                style: TextStyle(color: Theme.of(context).accentColor),
              ),
              // padding: EdgeInsets.all(5),
              shape: CircleBorder(),
            )
          : null,
    );
    // );
  }
}
