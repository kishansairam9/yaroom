import 'dart:convert';
import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yaroom/blocs/rooms.dart';
import '../components/contactView.dart';
import '../components/msgBox.dart';
import '../home/tabs.dart';
import '../components/roomsList.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/websocket.dart';
import '../../utils/types.dart';
import './channels.dart';

class Room extends StatefulWidget {
  static TabViewState? of(BuildContext context) =>
      context.findAncestorStateOfType<TabViewState>();

  @override
  RoomState createState() => RoomState();
  late final String roomId;
  late final String roomName;
  late final String? channelId;
  Room({required this.roomId, required this.roomName, this.channelId});
}

class RoomState extends State<Room> {
  //  Current State of InnerDrawerState
  late final webSocketSubscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller & subscription when the widget is disposed.
    webSocketSubscription.cancel();
    super.dispose();
  }

  _buildMessage(BuildContext context, RoomsMessage msg, bool prevIsSame,
      DateTime? prependDay) {
    var curUser = Provider.of<List<User>>(context, listen: false)
        .where((element) => element.userId == msg.fromUser)
        .toList()[0];
    final time = TimeOfDay.fromDateTime(msg.time).format(context);
    final double msgSpacing = prevIsSame ? 0 : 11;
    late final dateStr;
    if (DateTime.now().day == msg.time.day) {
      dateStr = "Today";
    } else if (DateTime.now().difference(msg.time).inDays == -1) {
      dateStr = "Yesterday";
    } else {
      dateStr =
          "${msg.time.day.toString().padLeft(2, "0")}/${msg.time.month.toString().padLeft(2, "0")}/${msg.time.year.toString().substring(2)}";
    }
    final msgContent = Bubble(
      borderWidth: 0,
      color: Colors.transparent,
      elevation: 0,
      // borderUp: false,
      margin: BubbleEdges.only(top: msgSpacing),
      alignment: Alignment.topLeft,
      // padding: BubbleEdges.all(10),
      child: Row(
        children: [
          Flexible(
              flex: 1,
              // child: Padding(
              //     padding: EdgeInsets.only(right: 5.0, top: 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: CircleAvatar(
                  backgroundColor: Colors.grey[350],
                  foregroundImage: curUser.profileImg == null
                      ? null
                      : NetworkImage('${curUser.profileImg}'),
                  backgroundImage: AssetImage('assets/no-profile.png'),
                  radius: 20.0,
                ),
              )
              // )
              ),
          Flexible(
              flex: 10,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  // margin: EdgeInsets.only(top: 7.0, bottom: 7.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                    // color: Colors.blueGrey,
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                            alignment: Alignment.topLeft,
                            child: Row(
                              children: [
                                Text(
                                  curUser.name,
                                  style: TextStyle(
                                      // color: Colors.grey,
                                      fontSize: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .fontSize,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  dateStr + " at " + time,
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .fontSize),
                                )
                              ],
                            )),
                        SizedBox(
                          height: 10,
                        ),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              msg.content!,
                              textAlign: TextAlign.left,
                              style: TextStyle(color: Colors.white),
                            )),
                      ]))),
        ],
      ),
    );
    if (prependDay == null) {
      return msgContent;
    }
    late final dateString;
    if (DateTime.now().day == prependDay.day) {
      dateString = "Today";
    } else if (DateTime.now().difference(prependDay).inDays == -1) {
      dateString = "Yesterday";
    } else {
      dateString =
          "${prependDay.day.toString().padLeft(2, "0")}/${prependDay.month.toString().padLeft(2, "0")}/${prependDay.year.toString().substring(2)}";
    }
    return Column(
      children: [
        Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: Theme.of(context).textTheme.subtitle1!.fontSize! / 2 +
                      msgSpacing,
                ),
                Divider(),
              ],
            ),
            Bubble(
              margin: BubbleEdges.only(top: msgSpacing),
              alignment: Alignment.center,
              color: Colors.transparent,
              elevation: 0,
              child: Text(dateString,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey[350],
                      fontSize:
                          Theme.of(context).textTheme.subtitle1!.fontSize)),
            ),
          ],
        ),
        msgContent
      ],
    );
  }

  void _sendMessage({
    required BuildContext context,
    required String channelId,
    String? content,
    String? media,
    int? replyTo,
  }) {
    if (media == '') media = null;
    if (content == '') content = null;
    if (media == null && content == null) {
      return;
    }

    Provider.of<WebSocketWrapper>(context, listen: false).add(jsonEncode({
      'type': 'RoomsMessage',
      'roomId': widget.roomId,
      'channelId': channelId,
      'fromUser': Provider.of<UserId>(context, listen: false),
      'content': content,
      'time': DateTime.now().toUtc().toIso8601String(),
      'media': media,
      'replyTo': replyTo,
    }));
  }

  Widget _buildMessagesView(List<RoomsMessage> allmsgs, String channelId) {
    var msgs =
        allmsgs.where((element) => element.channelId == channelId).toList();
    return Expanded(
        child: Column(
      children: [
        Expanded(
            child: ListView.builder(
                reverse: true,
                padding: EdgeInsets.only(top: 15.0),
                itemCount: msgs.length,
                itemBuilder: (BuildContext context, int index) {
                  final bool prevIsSame = msgs.length - 2 - index >= 0
                      ? (msgs[msgs.length - 2 - index].fromUser ==
                          msgs[msgs.length - 1 - index].fromUser)
                      : false;
                  final bool prependDayCond = msgs.length - 2 - index >= 0
                      ? (msgs[msgs.length - 2 - index].time.day !=
                          msgs[msgs.length - 1 - index].time.day)
                      : true;
                  DateTime? prependDay = prependDayCond
                      ? msgs[msgs.length - 1 - index].time
                      : null;
                  return _buildMessage(context, msgs[msgs.length - 1 - index],
                      prevIsSame, prependDay);
                }))
      ],
    ));
  }

  Future<bool> onBackPress() {
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    // late final String activeChannel = widget.currChannel;
    return BlocProvider(
      create: (context) => RoomsCubit(),
      child: Builder(builder: (context) {
        return BlocBuilder<RoomsCubit, Map<String, String>>(
          builder: (BuildContext context, Map<String, String> state) {
            return FutureBuilder(
                future: RepositoryProvider.of<AppDb>(context)
                    .getRoomMembers(roomID: widget.roomId)
                    .get(),
                builder: (BuildContext _,
                    AsyncSnapshot<List<User>> roomMembersSnapshot) {
                  if (roomMembersSnapshot.hasData) {
                    return FutureBuilder(
                        future: RepositoryProvider.of<AppDb>(context)
                            .getRoomChannelChat(roomId: widget.roomId)
                            .get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<List<RoomsMessage>>
                                roomChatsnapshot) {
                          if (roomChatsnapshot.hasData) {
                            return MultiProvider(
                                providers: [
                                  Provider<List<User>>(
                                      create: (_) => roomMembersSnapshot.data!),
                                  BlocProvider(
                                      lazy: false,
                                      create: (context) {
                                        var cubit = RoomChatCubit(
                                            roomId: widget.roomId,
                                            initialState:
                                                roomChatsnapshot.data!);
                                        webSocketSubscription =
                                            Provider.of<WebSocketWrapper>(
                                                    context,
                                                    listen: false)
                                                .stream
                                                .where((encodedData) {
                                          var data = jsonDecode(encodedData);
                                          return data['roomId'] ==
                                              widget.roomId;
                                        }).listen((encodedData) {
                                          var data = jsonDecode(encodedData);
                                          cubit.addMessage(
                                              msgId: data['msgId'],
                                              fromUser: data['fromUser'],
                                              roomId: data['roomId'],
                                              channelId: data['channelId'],
                                              time: DateTime.parse(data['time'])
                                                  .toLocal(),
                                              content: data['content'] == ''
                                                  ? null
                                                  : data['content'],
                                              media: data['media'] == ''
                                                  ? null
                                                  : data['media'],
                                              replyTo: data['replyTo'] == ''
                                                  ? null
                                                  : data['replyTo']);
                                        }, onError: (error) {
                                          print(error);
                                          return SnackBar(
                                              content: Text(
                                                  'Error has occured while receiving from websocket'));
                                        });
                                        return cubit;
                                      })
                                ],
                                child: Builder(builder: (context) {
                                  return Scaffold(
                                    appBar: AppBar(
                                      title: !state.containsKey(widget.roomId)
                                          ? Text("hi")
                                          : FutureBuilder(
                                              future: RepositoryProvider.of<
                                                      AppDb>(context)
                                                  .getChannelName(
                                                      roomId: widget.roomId,
                                                      channelId:
                                                          state[widget.roomId]!)
                                                  .get(),
                                              builder: (BuildContext context,
                                                  AsyncSnapshot<
                                                          List<RoomsChannel>>
                                                      snapshot) {
                                                if (snapshot.hasData) {
                                                  return ListTile(
                                                    // leading: Text("#"),
                                                    title: Text(
                                                      "# " +
                                                          snapshot.data![0]
                                                              .channelName,
                                                      style: TextStyle(
                                                          fontSize: 20),
                                                    ),
                                                  );
                                                } else if (snapshot.hasError) {
                                                  print(snapshot.error);
                                                  return SnackBar(
                                                      content: Text(
                                                          'Error has occured while reading from DB'));
                                                }
                                                return Container();
                                              }),
                                      leading: Builder(
                                        builder: (context) {
                                          return IconButton(
                                            icon: Icon(Icons.settings),
                                            onPressed: () {
                                              Scaffold.of(context).openDrawer();
                                            },
                                          );
                                        },
                                      ),
                                      actions: <Widget>[
                                        Builder(
                                          builder: (context) {
                                            return IconButton(
                                              icon: Icon(Icons.person),
                                              onPressed: () {
                                                Scaffold.of(context)
                                                    .openEndDrawer();
                                              },
                                            );
                                          },
                                        )
                                      ],
                                    ),
                                    body: !state.containsKey(widget.roomId)
                                        ? Container(color: Colors.red)
                                        : Builder(
                                            builder: (context) {
                                              return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: <Widget>[
                                                    BlocBuilder<RoomChatCubit,
                                                        List<RoomsMessage>>(
                                                      builder: (BuildContext
                                                                  context,
                                                              List<RoomsMessage>
                                                                  chatstate) =>
                                                          _buildMessagesView(
                                                              chatstate,
                                                              state[widget
                                                                  .roomId]!),
                                                    ),
                                                    MsgBox(
                                                      sendMessage: _sendMessage,
                                                      channelId:
                                                          state[widget.roomId],
                                                    )
                                                  ]);
                                            },
                                          ),
                                    drawer: SafeArea(
                                      child: Drawer(
                                        child: Scaffold(
                                            appBar: AppBar(
                                              automaticallyImplyLeading: false,
                                              title: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 2,
                                                    child: Container(
                                                      // width: 50,
                                                      child: IconButton(
                                                          padding:
                                                              EdgeInsets.all(2),
                                                          icon: Icon(Icons.home,
                                                              size: 30),
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pushReplacementNamed(
                                                                      '/')),
                                                    ),
                                                  ),
                                                  // VerticalDivider(color: Colors.grey, width: 2),
                                                  Expanded(
                                                      flex: 8,
                                                      child:
                                                          Text(widget.roomName))
                                                ],
                                              ),
                                            ),
                                            body: Row(
                                              children: [
                                                Expanded(
                                                    flex: 2,
                                                    child: RoomListView()),
                                                // VerticalDivider(color: Colors.grey, width: 2),
                                                Expanded(
                                                    flex: 8,
                                                    child: ChannelsView(
                                                      roomId: widget.roomId,
                                                    ))
                                              ],
                                            )),
                                      ),
                                    ),
                                    endDrawer: Drawer(
                                      child: ListView(
                                          padding: EdgeInsets.zero,
                                          children: [
                                            DrawerHeader(
                                                child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                  ListTile(
                                                    tileColor:
                                                        Colors.transparent,
                                                    title: Text(widget.roomName,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            fontSize: 20)),
                                                  ),
                                                  Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      children: [
                                                        Column(
                                                          children: [
                                                            IconButton(
                                                                onPressed: () =>
                                                                    {},
                                                                tooltip:
                                                                    "Pinned Messages",
                                                                icon: Icon(Icons
                                                                    .push_pin)),
                                                            Text("Pins")
                                                          ],
                                                        ),
                                                        Column(
                                                          children: [
                                                            IconButton(
                                                                onPressed: () =>
                                                                    {},
                                                                tooltip:
                                                                    "Search",
                                                                icon: Icon(Icons
                                                                    .search)),
                                                            Text("Search")
                                                          ],
                                                        )
                                                      ])
                                                ])),
                                            ...roomMembersSnapshot.data!.map(
                                                (User e) => ListTile(
                                                    onTap: () =>
                                                        showModalBottomSheet(
                                                            context: context,
                                                            builder:
                                                                (BuildContext
                                                                    c) {
                                                              return ViewContact(
                                                                  e);
                                                            }),
                                                    tileColor:
                                                        Colors.transparent,
                                                    leading: CircleAvatar(
                                                      backgroundColor:
                                                          Colors.grey[350],
                                                      foregroundImage:
                                                          NetworkImage(
                                                              '${e.profileImg}'),
                                                      backgroundImage: AssetImage(
                                                          'assets/no-profile.png'),
                                                    ),
                                                    title: Text(
                                                      e.name,
                                                    )))
                                          ]),
                                    ),
                                  );
                                }));
                          }
                          return CircularProgressIndicator();
                        });
                  } else if (roomMembersSnapshot.hasError) {
                    print(roomMembersSnapshot.error);
                    return SnackBar(
                        content: Text(
                            'Error has occured while reading from local DB'));
                  }
                  return CircularProgressIndicator();
                });
          },
        );
      }),
    );
  }
}
