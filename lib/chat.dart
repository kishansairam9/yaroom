import 'package:flutter/material.dart';
import 'package:faker/faker.dart';
import 'package:badges/badges.dart';
import 'dart:math';

class ChatView extends StatefulWidget {
  @override
  ChatViewState createState() => ChatViewState();
}

class ChatViewState extends State<ChatView> {
  final _chats = <ProfileView>[];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: 30,
        itemBuilder: (context, index) {
          if (index >= _chats.length) {
            for (int i = 0; i < 10; i++) {
              _chats.add(ProfileView());
            }
          }

          return _chats[index];
        });
  }
}

class ProfileView extends StatefulWidget {
  final randGen = Random();

  @override
  ProfileViewState createState() => ProfileViewState();
}

class ProfileViewState extends State<ProfileView> {
  late final int _unread;
  late final _image;
  late final _contactName;

  // TODO: For some reason profile name and image change every time I scroll back to top as well :<
  ProfileViewState() {
    _unread = widget.randGen.nextInt(20);
    _image = faker.image.image(
        width: 150, height: 150, keywords: ['people', 'nature'], random: true);
    _contactName = faker.person.name();
  }

  void _showChat() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: ListTile(
              contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
              tileColor: Colors.transparent,
              onTap: _showChat,
              leading: CircleAvatar(
                backgroundColor: Colors.grey[350],
                foregroundImage: NetworkImage('$_image'),
                backgroundImage: AssetImage('assets/no-profile.png'),
              ),
              title: Text(_contactName),
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
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: _showChat,
        leading: CircleAvatar(
          backgroundColor: Colors.grey[350],
          foregroundImage: NetworkImage('$_image'),
          backgroundImage: AssetImage('assets/no-profile.png'),
        ),
        title: Text(_contactName),
        trailing: Badge(
          // TODO: Badge sizes differ for 1 digit and 2, 3 digits etc, fix this incositency
          // Pad left space doesn't help
          badgeContent: Text('$_unread'),
          badgeColor: Theme.of(context).accentColor,
          padding: EdgeInsets.all(10),
        ),
      ),
    );
  }
}
