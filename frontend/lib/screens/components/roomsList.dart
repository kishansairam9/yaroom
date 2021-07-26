import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import '../../utils/types.dart';

class RoomListView extends StatefulWidget {
  final _rooms = <RoomsList>[];

  get tiles => _rooms;

  @override
  RoomListViewState createState() => RoomListViewState();
}

class RoomListViewState extends State<RoomListView> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: RepositoryProvider.of<AppDb>(context)
            .getRoomsOfUser(userID: RepositoryProvider.of<UserId>(context))
            .watch(),
        builder: (BuildContext context,
            AsyncSnapshot<List<RoomsListData>> snapshot) {
          if (snapshot.hasData) {
            return ListView(
                children: snapshot.data!
                    .map((e) => RoomsList(
                        roomId: e.roomId, name: e.name, image: e.roomIcon))
                    .toList());
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return SnackBar(
                content: Text('Error has occured while reading from DB'));
          }
          return Container();
        });
  }
}

class RoomsList extends StatefulWidget {
  late final String roomId;
  late final String? image;
  late final String name;

  late final int? _unread;

  RoomsList({
    required this.roomId,
    required this.name,
    this.image,
    int? unread,
  }) {
    _unread = unread;
  }

  @override
  RoomsListState createState() => RoomsListState(unread: _unread);
}

class RoomsListState extends State<RoomsList> {
  int _unread = 0;

  RoomsListState({
    int? unread,
  }) {
    _unread = unread ?? Random().nextInt(20);
  }

  Widget build(BuildContext context) {
    return Column(children: [
      CircleAvatar(
          backgroundColor: Colors.grey[350],
          foregroundImage:
              widget.image == null ? null : NetworkImage('${widget.image}'),
          backgroundImage: AssetImage('assets/no-profile.png'),
          radius: 27.0,
          child: GestureDetector(
              onTap: () => Navigator.of(context).pushReplacementNamed('/rooms',
                  arguments: RoomArguments(widget.roomId, widget.name)))),
      SizedBox(
        height: 6,
      )
    ]);
  }
}
