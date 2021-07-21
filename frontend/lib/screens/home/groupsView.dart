import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'groupPage.dart';
import '../../utils/types.dart';

class GroupChatView extends StatefulWidget {
  final _chats = <GroupProfileTile>[];

  get tiles => _chats;

  @override
  GroupChatViewState createState() => GroupChatViewState();
}

class GroupChatViewState extends State<GroupChatView> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: RepositoryProvider.of<AppDb>(context)
            .getGroupsOfUser(userID: RepositoryProvider.of<UserId>(context))
            .watch(),
        builder: (BuildContext context, AsyncSnapshot<List<GroupDM>> snapshot) {
          if (snapshot.hasData) {
            return ListView(
                children: ListTile.divideTiles(
              context: context,
              tiles: snapshot.data!.map((e) => GroupProfileTile(
                  groupId: e.groupId, name: e.name, image: e.groupIcon)),
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

class GroupProfileTile extends StatefulWidget {
  late final String groupId;
  late final String? image;
  late final String name;

  late final List<dynamic> _preParams;
  late final Function? _preShowChat;

  late final int? _unread;
  late final String? _showText;

  GroupProfileTile(
      {required this.groupId,
      required this.name,
      this.image,
      int? unread,
      String? showText,
      Function? preShowChat,
      List<dynamic>? preParams}) {
    _preShowChat = preShowChat ?? null;
    if (preParams != null && _preShowChat == null) {
      // Shouldn't be done, raising null exception
      preShowChat!;
    }
    _preParams = preParams ?? [];
    _unread = unread;
    _showText = showText;
  }

  @override
  GroupProfileTileState createState() => GroupProfileTileState(
      unread: _unread,
      showText: _showText,
      preParams: _preParams,
      preShowChat: _preShowChat);
}

class GroupProfileTileState extends State<GroupProfileTile> {
  int _unread = 0;
  String _showText = '';

  GroupProfileTileState(
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
      return GroupChatPage(
          groupId: widget.groupId, name: widget.name, image: widget.image);
      // return Container();
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
        foregroundImage:
            widget.image == null ? null : NetworkImage('${widget.image}'),
        backgroundImage: AssetImage('assets/no-profile.png'),
        radius: 28.0,
      ),
      title: Text(widget.name),
      subtitle: Text(_showText),
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
