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
            print(snapshot.error);
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

  late final List<dynamic> _preParams;
  late final Function? _preShowChat;

  late final int _unread;
  late final String _showText;

  ProfileTile(
      {required this.userId,
      required this.image,
      required this.name,
      int? unread,
      String? showText,
      Function? preShowChat,
      List<dynamic>? preParams}) {
    _preShowChat = preShowChat ?? null;
    _preParams = preParams ?? [];
    _unread = unread ?? Random().nextInt(20);
    _showText = showText ?? '';
  }

  @override
  ProfileTileState createState() => ProfileTileState(
      unread: _unread,
      showText: _showText,
      preParams: _preParams,
      preShowChat: _preShowChat);
}

class ProfileTileState extends State<ProfileTile> {
  int _unread = 0;
  String _showText = '';

  ProfileTileState(
      {int? unread,
      String? showText,
      Function? preShowChat,
      List<dynamic>? preParams}) {
    _unread = unread ?? Random().nextInt(20);
    _showText = showText ?? '';
  }

  void _showChat() {
    if (widget._preShowChat != null) {
      Function.apply(widget._preShowChat!, widget._preParams);
    }
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
      subtitle: _showText.isEmpty ? null : Text(_showText),
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
