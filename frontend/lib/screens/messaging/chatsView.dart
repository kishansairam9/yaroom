import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/chatMeta.dart';
import '../../utils/types.dart';
import '../../utils/notifiers.dart';
import 'package:provider/provider.dart';

class ChatView extends StatefulWidget {
  final _chats = <ProfileTile>[];

  get tiles => _chats;

  @override
  ChatViewState createState() => ChatViewState();
}

class ChatViewState extends State<ChatView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DMsList>(builder: (_, DMsList dMsList, __) {
      return FutureBuilder(
          future: dMsList.updateChats(context),
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            if (snapshot.hasData) {
              return ListView(
                  children: ListTile.divideTiles(
                context: context,
                tiles: dMsList.chats
                    .where((e) =>
                        e.userId != Provider.of<UserId>(context, listen: false))
                    .map((e) => ProfileTile(userId: e.userId, name: e.name)),
              ).toList());
            } else if (snapshot.hasError) {
              print(snapshot.error);
              return SnackBar(
                  content: Text('Error has occured while reading from DB'));
            }
            return CircularProgressIndicator();
          });
    });
  }
}

class ProfileTile extends StatefulWidget {
  late final String userId;
  late final String name;

  late final List<dynamic> _preParams;
  late final Function? _preShowChat;

  ProfileTile(
      {required this.userId,
      required this.name,
      Function? preShowChat,
      List<dynamic>? preParams}) {
    _preShowChat = preShowChat ?? null;
    if (preParams != null && _preShowChat == null) {
      // Shouldn't be done, raising null exception
      preShowChat!;
    }
    _preParams = preParams ?? [];
  }

  @override
  ProfileTileState createState() => ProfileTileState();
}

class ProfileTileState extends State<ProfileTile> {
  ProfileTileState();

  void _showChat() {
    if (widget._preShowChat != null) {
      Function.apply(widget._preShowChat!, widget._preParams);
    }
    Future.delayed(Duration(milliseconds: 500), () async {
      // TODO Add new MOOR query to get only last msg!!
      List<ChatMessage> uChat = await Provider.of<AppDb>(context, listen: false)
          .getUserChat(otherUser: widget.userId)
          .get();
      String lastMsg = uChat.last.msgId;
      Provider.of<ChatMetaCubit>(context, listen: false)
          .read(getExchangeId(), lastMsg, context);
    });
    Navigator.of(context).pushNamed('/chat',
        arguments: ChatPageArguments(userId: widget.userId, name: widget.name));
  }

  String getExchangeId() {
    var ids = <String>[
      Provider.of<UserId>(context, listen: false),
      widget.userId
    ];
    ids.sort();
    return ids[0] + ":" + ids[1];
  }

  @override
  Widget build(BuildContext context) {
    // return Card(
    return ListTile(
      minVerticalPadding: 25.0,
      onTap: _showChat,
      leading: CircleAvatar(
        backgroundColor: Colors.grey[350],
        foregroundImage: iconImageWrapper(widget.userId),
        radius: 28.0,
      ),
      title: Text(widget.name),
      subtitle: BlocBuilder<ChatMetaCubit, ChatMetaState>(
          bloc: Provider.of<ChatMetaCubit>(context, listen: false),
          builder: (context, ChatMetaState state) {
            return Text(state.getLastMsgPreview(getExchangeId()));
          }),
      trailing: BlocBuilder<ChatMetaCubit, ChatMetaState>(
          bloc: Provider.of<ChatMetaCubit>(context, listen: false),
          builder: (context, ChatMetaState state) {
            int unread = state.getUnread(getExchangeId());
            return MaterialButton(
              onPressed: () {},
              color: unread > 0 ? Colors.blueGrey[400] : Colors.transparent,
              height: unread == 0 ? 0 : null,
              child: unread == 0
                  ? null
                  : Text(
                      '$unread',
                      style: TextStyle(color: Theme.of(context).accentColor),
                    ),
              // padding: EdgeInsets.all(5),
              shape: CircleBorder(),
            );
            // }
            // return Container();
          }),
    );
    // );
  }
}
