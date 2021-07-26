import 'package:flutter/material.dart';
import 'package:yaroom/blocs/rooms.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/types.dart';
import 'dart:math';

class ChannelsView extends StatefulWidget {
  final _channels = <ChannelsTile>[];
  late final String roomId;
  late final String roomName;
  late final String currChannelID;
  get tiles => _channels;

  ChannelsView({
    required this.roomId,
    required this.roomName,
  });

  @override
  ChannelsViewState createState() => ChannelsViewState();
}

class ChannelsViewState extends State<ChannelsView> {
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: RepositoryProvider.of<AppDb>(context)
            .getChannelsOfRoom(roomID: widget.roomId)
            .watch(),
        builder:
            (BuildContext context, AsyncSnapshot<List<RoomsChannel>> snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  RoomsChannel e = snapshot.data![index];
                  ChannelsTile tile = ChannelsTile(
                      roomId: widget.roomId,
                      channelId: e.channelId,
                      name: e.channelName);
                  if (index == 0) {
                    return Column(
                      children: [Text(widget.roomName), tile],
                    );
                  }
                  return tile;
                });
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return SnackBar(
                content: Text('Error has occured while reading from DB'));
          }
          return Container();
        });
  }
}

class ChannelsTile extends StatefulWidget {
  late final String channelId;
  late final String name;
  late final String roomId;
  late final bool? _unread;

  ChannelsTile({
    required this.roomId,
    required this.channelId,
    required this.name,
    bool? unread,
  }) {
    _unread = unread;
  }

  @override
  ChannelsTileState createState() => ChannelsTileState(unread: _unread);
}

class ChannelsTileState extends State<ChannelsTile> {
  bool _unread = false;

  ChannelsTileState({
    bool? unread,
  }) {
    _unread = unread ?? (Random().nextInt(2) == 0 ? false : true);
    // _unread = true;
  }
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 5,
      // leading: Text("#"),
      onTap: () {
        Navigator.of(context).pop();
        BlocProvider.of<RoomsCubit>(context, listen: false)
            .updateDefaultChannel(widget.roomId, widget.channelId);
      },
      title: Text("# " + widget.name),
      trailing: _unread
          ? Container(
              width: 15.0,
              height: 15.0,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
