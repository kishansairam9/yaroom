import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaroom/blocs/rooms.dart';
import '../../utils/types.dart';

class RoomListView extends StatefulWidget {
  final _rooms = <RoomTile>[];

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
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                RoomsListData e = snapshot.data![index];
                return RoomTile(
                    roomId: e.roomId, name: e.name, image: e.roomIcon);
              },
            );
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return SnackBar(
                content: Text('Error has occured while reading from DB'));
          }
          return Container();
        });
  }
}

class RoomTile extends StatefulWidget {
  late final String roomId;
  late final String? image;
  late final String name;

  RoomTile({
    required this.roomId,
    required this.name,
    this.image,
  });

  @override
  RoomTileState createState() => RoomTileState();
}

class RoomTileState extends State<RoomTile> {
  RoomTileState();

  Widget build(BuildContext context) {
    return Column(children: [
      CircleAvatar(
          backgroundColor: Colors.grey[350],
          foregroundImage:
              widget.image == null ? null : NetworkImage('${widget.image}'),
          backgroundImage: AssetImage('assets/no-profile.png'),
          radius: 27.0,
          child: GestureDetector(onTap: () {
            BlocProvider.of<RoomsCubit>(context, listen: false)
                .updateLastActive(
                    RoomDetails(roomId: widget.roomId, roomName: widget.name));
            Navigator.of(context).pushReplacementNamed('/',
                arguments: HomePageArguments(
                    index: 0,
                    roomId: widget.roomId,
                    roomName: widget.name,
                    roomIcon: widget.image));
          })),
      SizedBox(
        height: 6,
      )
    ]);
  }
}
