import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:yaroom/blocs/roomMetadata.dart';
import 'package:yaroom/blocs/rooms.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaroom/utils/backendRequests.dart';
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
    // required this.roomName,
  });

  @override
  ChannelsViewState createState() => ChannelsViewState();
}

class ChannelsViewState extends State<ChannelsView> {
  Widget build(BuildContext context) {
    return BlocBuilder<RoomMetadataCubit, RoomMetadataMap>(
        builder: (BuildContext context, state) {
      if (state.data.containsKey(widget.roomId)) {
        List<RoomsChannel> roomchannellist = [];
        state.data[widget.roomId]!.roomChannels.forEach((k, v) =>
            roomchannellist.add(RoomsChannel(
                roomId: widget.roomId, channelId: k, channelName: v)));
        return ListView.builder(
            itemCount: roomchannellist.length,
            itemBuilder: (context, index) {
              RoomsChannel e = roomchannellist[index];
              ChannelsTile tile = ChannelsTile(
                  roomId: widget.roomId,
                  channelId: e.channelId,
                  name: e.channelName);
              if (index == 0) {
                return Column(
                  children: [Text(state.data[widget.roomId]!.name), tile],
                );
              }
              return tile;
            });
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

  Widget editChannel(BuildContext context, String channelid) {
    var ChannelController = TextEditingController();
    return BlocBuilder<RoomMetadataCubit, RoomMetadataMap>(
      builder: (context, state) {
        return AlertDialog(
          scrollable: true,
          title: Text('Edit Channel'),
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: ChannelController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      icon: Icon(Icons.edit),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
                child: Text("Delete Channel"),
                onPressed: () async {
                  var res =
                      await deleteChannel(widget.roomId, channelid, context);
                  if (res == null) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Channel Delete Failed, try again!')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                }),
            ElevatedButton(
                child: Text("Submit"),
                onPressed: () async {
                  if (ChannelController.text != '') {
                    var newRoomChannels =
                        state.data[widget.roomId]!.roomChannels;
                    newRoomChannels[channelid] = ChannelController.text;

                    var res = await editRoom(
                        jsonEncode(<String, dynamic>{
                          "roomId": widget.roomId,
                          "name": state.data[widget.roomId]!.name,
                          "description": state.data[widget.roomId]!.description,
                          "roomMembers": state.data[widget.roomId]!.roomMembers
                              .map((e) => e.userId)
                              .toList(),
                          "channelsList": newRoomChannels
                        }),
                        context);
                    if (res == null) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Channel Edit Failed, try again!')),
                      );
                      return;
                    }
                    Navigator.pop(context);
                  }
                })
          ],
        );
      },
    );
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
      onLongPress: () {
        showDialog(
            context: context,
            builder: (BuildContext newcontext) {
              return editChannel(newcontext, widget.channelId);
            });
      },
      title: !_unread
          ? Text("# " + widget.name)
          : Text(
              "# " + widget.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
    );
  }
}
