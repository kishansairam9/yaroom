import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'chatPage.dart';
import '../../utils/types.dart';

class ChatView extends StatefulWidget {
  final _chats = <ProfileTile>[];

  get tiles => _chats;

  @override
  ChatViewState createState() => ChatViewState();
}

class ChatViewState extends State<ChatView> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: RepositoryProvider.of<AppDb>(context).getAllUsers().watch(),
        builder: (BuildContext context, AsyncSnapshot<List<User>> snapshot) {
          if (snapshot.hasData) {
            return ListView(
                children: ListTile.divideTiles(
              context: context,
              tiles: snapshot.data!.map((e) => ProfileTile(
                  userId: e.userId, name: e.name, image: e.profileImg)),
            ).toList());
          } else if (snapshot.hasError) {
            print(snapshot.data);
            return SnackBar(
                content: Text('Error has occured while reading from DB'));
          }
          return Container();
        });
  }
}

class ProfileTile extends StatefulWidget {
  late final int userId;
  late final image;
  late final String name;

  ProfileTile({required this.userId, required this.image, required this.name});

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
      return ChatPage(
          userId: widget.userId, name: widget.name, image: widget.image);
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
