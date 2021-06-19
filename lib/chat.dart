import 'package:flutter/material.dart';
import 'package:faker/faker.dart';
import 'package:badges/badges.dart';
import 'dart:math';

class ChatView extends StatefulWidget {
  final _chats = <ProfileView>[];

  get tiles => _chats;

  ChatView() {
    for (int i = 0; i < 30; i++) {
      _chats.add(ProfileView());
    }
  }

  @override
  ChatViewState createState() => ChatViewState();
}

class ChatViewState extends State<ChatView> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: widget._chats,
    );
  }
}

class ProfileView extends StatefulWidget {
  late final _image;
  late final String _name;

  get image => _image;
  get name => _name;

  ProfileView() {
    _image = faker.image.image(
        width: 150, height: 150, keywords: ['people', 'nature'], random: true);
    _name = faker.person.name();
  }

  @override
  ProfileViewState createState() => ProfileViewState();
}

class ChatPage extends StatelessWidget {
  final name, image;

  ChatPage({required this.name, this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: ListTile(
            contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
            tileColor: Colors.transparent,
            leading: CircleAvatar(
              backgroundColor: Colors.grey[350],
              foregroundImage: NetworkImage('$image'),
              backgroundImage: AssetImage('assets/no-profile.png'),
            ),
            title: Text(name),
          ),
          actions: <Widget>[
            IconButton(
              onPressed: () => {},
              icon: Icon(Icons.phone),
              tooltip: 'Call',
            ),
            IconButton(
              onPressed: () => {},
              icon: Icon(Icons.more_vert),
              tooltip: 'More',
            )
          ],
        ),
        body: Center(
          child: Text('Dummy'),
        ));
  }
}

class ProfileViewState extends State<ProfileView> {
  int _unread = 0;
  String _lastChat = '';

  ProfileViewState() {
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
    return Card(
      child: ListTile(
        onTap: _showChat,
        leading: CircleAvatar(
          backgroundColor: Colors.grey[350],
          foregroundImage: NetworkImage('${widget.image}'),
          backgroundImage: AssetImage('assets/no-profile.png'),
        ),
        title: Text(widget.name),
        subtitle: _lastChat.isEmpty ? null : Text(_lastChat),
        trailing: _unread > 0
            ? Badge(
                // TODO: Badge sizes differ for 1 digit and 2, 3 digits etc, fix this incositency
                // Pad left space doesn't help
                badgeContent: Text('$_unread'),
                badgeColor: Theme.of(context).accentColor,
                padding: EdgeInsets.all(10),
                // TODO: Badges float around when puled from bottom to top agressively, should animate even slightly
              )
            : null,
      ),
    );
  }
}
