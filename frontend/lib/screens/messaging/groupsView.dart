import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:yaroom/blocs/groupMetadata.dart';
import '../../utils/types.dart';
import '../../utils/notifiers.dart';
import '../../blocs/chatMeta.dart';

class GroupChatView extends StatefulWidget {
  GroupChatView({Key? key}) : super(key: key);
  final _chats = <GroupProfileTile>[];
  get tiles => _chats;

  @override
  GroupChatViewState createState() => GroupChatViewState();
}

class GroupChatViewState extends State<GroupChatView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GroupsList>(builder: (_, GroupsList groupsList, __) {
      return Stack(
        children: [
          BlocBuilder<GroupMetadataCubit, GroupMetadataMap>(
              builder: (BuildContext context, state) {
            List<GroupProfileTile> tiles = [];
            state.data.forEach((k, v) => tiles
                .add(GroupProfileTile(groupId: k, name: state.data[k]!.name)));
            return ListView(
                children: ListTile.divideTiles(context: context, tiles: tiles)
                    .toList());
          }),
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              child: Icon(Icons.people),
              onPressed: () => Navigator.of(context)
                  .pushNamed('/editgroup', arguments: {"groupId": ""}),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          )
        ],
      );
    });
  }
}

class GroupProfileTile extends StatefulWidget {
  late final String groupId;
  late final String? description;
  late final String name;

  late final List<dynamic> _preParams;
  late final Function? _preShowChat;

  GroupProfileTile(
      {required this.groupId,
      required this.name,
      this.description,
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
  GroupProfileTileState createState() => GroupProfileTileState();
}

class GroupProfileTileState extends State<GroupProfileTile> {
  GroupProfileTileState();

  void _showChat() {
    if (widget._preShowChat != null) {
      Function.apply(widget._preShowChat!, widget._preParams);
    }
    Future.delayed(Duration(milliseconds: 500), () async {
      // TODO Add new MOOR query to get only last msg!!
      List<GroupChatMessage> uChat =
          await Provider.of<AppDb>(context, listen: false)
              .getGroupChat(groupId: widget.groupId)
              .get();
      if (uChat.length > 0) {
        String lastMsg = uChat.last.msgId;
        Provider.of<ChatMetaCubit>(context, listen: false)
            .read(widget.groupId, lastMsg, context);
      }
    });
    Navigator.of(context).pushNamed('/groupchat',
        arguments: GroupChatPageArguments(groupId: widget.groupId));
  }

  @override
  Widget build(BuildContext context) {
    // return Card(
    return ListTile(
      minVerticalPadding: 25.0,
      onTap: _showChat,
      leading: CircleAvatar(
        backgroundColor: Colors.grey[350],
        foregroundImage: iconImageWrapper(widget.groupId),
        radius: 28.0,
      ),
      title: Text(widget.name),
      subtitle: BlocBuilder<ChatMetaCubit, ChatMetaState>(
          bloc: Provider.of<ChatMetaCubit>(context, listen: false),
          builder: (context, ChatMetaState state) {
            return Text(state.getLastMsgPreview(widget.groupId));
          }),
      trailing: BlocBuilder<ChatMetaCubit, ChatMetaState>(
          bloc: Provider.of<ChatMetaCubit>(context, listen: false),
          builder: (context, ChatMetaState state) {
            int unread = state.getUnread(widget.groupId);
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
  }
}
