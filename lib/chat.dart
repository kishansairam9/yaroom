import 'package:flutter/material.dart';
import 'package:faker/faker.dart';
import 'package:badges/badges.dart';
import 'dart:math';

class ChatView extends StatefulWidget {
  final _chats = <ProfileView>[];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('yaroom'),
        actions: <Widget>[
          IconButton(
            onPressed: () => {},
            icon: Icon(Icons.settings_applications),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                // TODO: Currently using only chats, replace with contact list or something like that
                delegate: ChatViewSearchDelegate(chats: widget._chats),
              );
            },
            tooltip: 'Search',
          ),
        ],
      ),
      body: ListView(
        children: widget._chats,
      ),
    );
  }
}

class ChatViewSearchDelegate extends SearchDelegate {
  final List<ProfileView> chats;

  ChatViewSearchDelegate({required this.chats});

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
          onPressed: () => {close(context, null)},
          icon: Icon(Icons.close),
          tooltip: 'Cancel')
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        onPressed: () => {close(context, null)},
        icon: Icon(Icons.arrow_back),
        tooltip: 'Cancel');
  }

  Widget nameSearch(BuildContext context) {
    var results = chats
        .where((ProfileView x) =>
            x.name.toLowerCase().contains(query.toLowerCase()))
        .map((e) {
      return Card(
        child: ListTile(
          onTap: () {
            close(context, null); // TODO: Is this casuing buggy transisiton?
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (BuildContext context) {
              return ChatPage(name: e.name, image: e.image);
            }));
          },
          leading: CircleAvatar(
            backgroundColor: Colors.grey[350],
            foregroundImage: NetworkImage('${e.image}'),
            backgroundImage: AssetImage('assets/no-profile.png'),
          ),
          title: Text(e.name),
        ),
      );
    }).toList();
    if (results.isEmpty) {
      return Center(
        child: Text("No matches"),
      );
    }
    return ListView(children: results);
  }

  @override
  Widget buildResults(BuildContext context) {
    return nameSearch(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return nameSearch(context);
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
              foregroundImage: NetworkImage('${image}'),
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
