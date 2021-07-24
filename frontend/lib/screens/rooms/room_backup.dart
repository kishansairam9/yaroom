import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb; // Web detection
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yaroom/blocs/groupChats.dart';
import 'package:yaroom/blocs/rooms.dart';
import '../../utils/inner_drawer.dart';
import '../home/tabs.dart';
import '../components/roomsList.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/websocket.dart';
import '../../utils/types.dart';
import 'dart:math';

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
  final inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller & subscription when the widget is disposed.
    webSocketSubscription.cancel();
    inputController.dispose();
    super.dispose();
  }

  _buildMessage(BuildContext context, RoomsMessage msg) {
    var curUser = Provider.of<List<User>>(context, listen: false)
        .where((element) => element.userId == msg.fromUser)
        .toList()[0];
    return Container(
        padding: EdgeInsets.only(
          left: 5.0,
          right: 5.0,
        ),
        child: Align(
            alignment: Alignment.topCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5.0),
                        margin: EdgeInsets.only(top: 7.0, bottom: 7.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(15.0)),
                          // color: Colors.blueGrey,
                        ),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    curUser.name,
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: Theme.of(context)
                                            .textTheme
                                            .overline!
                                            .fontSize),
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
                            ])))
              ],
            )));
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

  Widget _buildMessagesView(List<RoomsMessage> msgs) {
    return Expanded(
        child: Column(
      children: [
        Expanded(
            child: ListView.builder(
                reverse: true,
                padding: EdgeInsets.only(top: 15.0),
                itemCount: msgs.length,
                itemBuilder: (BuildContext context, int index) {
                  return _buildMessage(context, msgs[msgs.length - 1 - index]);
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
                    return Scaffold(
                      appBar: AppBar(
                        title: !state.containsKey(widget.roomId)
                            ? Text("hi")
                            : FutureBuilder(
                                future: RepositoryProvider.of<AppDb>(context)
                                    .getChannelName(
                                        roomId: widget.roomId,
                                        channelId: state[widget.roomId]!)
                                    .get(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<List<RoomsChannel>>
                                        snapshot) {
                                  if (snapshot.hasData) {
                                    return Text(snapshot.data![0].channelName);
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
                                  Scaffold.of(context).openEndDrawer();
                                },
                              );
                            },
                          )
                        ],
                      ),
                      body: !state.containsKey(widget.roomId)
                          ? Container(color: Colors.red)
                          : FutureBuilder(
                              future: RepositoryProvider.of<AppDb>(context)
                                  .getRoomChannelChat(
                                      roomId: widget.roomId,)
                                      // channelId: state[widget.roomId]!)
                                  .get(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<List<RoomsMessage>>
                                      roomChatsnapshot) {
                                if (roomChatsnapshot.hasData) {
                                  print('abcd');
                                  // return Text(
                                  //     roomChatsnapshot.data![0].channelId);
                                  return MultiProvider(
                                    providers: [
                                      Provider<List<User>>(
                                          create: (_) =>
                                              roomMembersSnapshot.data!),
                                      BlocProvider(
                                          lazy: false,
                                          create: (context) {
                                            print('holahola');
                                            var cubit = RoomChatCubit(
                                                roomId: widget.roomId,
                                                // channelId:
                                                //     state[widget.roomId]!,
                                                initialState:
                                                    roomChatsnapshot.data!);
                                            webSocketSubscription =
                                                Provider.of<WebSocketWrapper>(
                                                        context,
                                                        listen: false)
                                                    .stream
                                                    .where((encodedData) {
                                              var data =
                                                  jsonDecode(encodedData);
                                              return data['roomId'] ==
                                                      widget.roomId &&
                                                  data['channelId'] ==
                                                      state[widget.roomId];
                                            }).listen((encodedData) {
                                              var data =
                                                  jsonDecode(encodedData);
                                              cubit.addMessage(
                                                  msgId: data['msgId'],
                                                  fromUser: data['fromUser'],
                                                  roomId: data['roomId'],
                                                  channelId: data['channelId'],
                                                  time: DateTime.parse(
                                                      data['time']),
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
                                    child: Builder(
                                      builder: (context) {
                                        return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: <Widget>[
                                              BlocBuilder<RoomChatCubit,
                                                  List<RoomsMessage>>(
                                                builder: (BuildContext context,
                                                        List<RoomsMessage>
                                                            chatstate) =>
                                                    _buildMessagesView(
                                                        chatstate),
                                              ),
                                              // Row(
                                              //   children: [
                                              //     Expanded(
                                              //         child:
                                              //             RawKeyboardListener(
                                              //                 focusNode:
                                              //                     FocusNode(),
                                              //                 onKey:
                                              //                     (RawKeyEvent
                                              //                         event) {
                                              //                   if (kIsWeb ||
                                              //                       Platform
                                              //                           .isMacOS ||
                                              //                       Platform
                                              //                           .isLinux ||
                                              //                       Platform
                                              //                           .isWindows) {
                                              //                     // Submit on Enter and new line on Shift + Enter only on desktop devices or Web
                                              //                     if (event.isKeyPressed(
                                              //                             LogicalKeyboardKey
                                              //                                 .enter) &&
                                              //                         !event
                                              //                             .isShiftPressed) {
                                              //                       String
                                              //                           data =
                                              //                           inputController
                                              //                               .text;
                                              //                       inputController
                                              //                           .clear();
                                              //                       // Bug fix for stray new line after Pressing Enter
                                              //                       Future.delayed(
                                              //                           Duration(
                                              //                               milliseconds:
                                              //                                   100),
                                              //                           () => inputController
                                              //                               .clear());
                                              //                       _sendMessage(
                                              //                           channelId:
                                              //                               state[widget
                                              //                                   .roomId]!,
                                              //                           context:
                                              //                               context,
                                              //                           content:
                                              //                               data.trim());
                                              //                     }
                                              //                   }
                                              //                 },
                                              //                 child: TextField(
                                              //                   maxLines: null,
                                              //                   controller:
                                              //                       inputController,
                                              //                   textCapitalization:
                                              //                       TextCapitalization
                                              //                           .sentences,
                                              //                   onEditingComplete:
                                              //                       () {
                                              //                     String data =
                                              //                         inputController
                                              //                             .text;
                                              //                     inputController
                                              //                         .clear();
                                              //                     _sendMessage(
                                              //                         channelId:
                                              //                             state[widget
                                              //                                 .roomId]!,
                                              //                         context:
                                              //                             context,
                                              //                         content: data
                                              //                             .trim());
                                              //                   },
                                              //                   decoration: InputDecoration(
                                              //                       border:
                                              //                           OutlineInputBorder(),
                                              //                       hintText:
                                              //                           'Type a message'),
                                              //                 ))),
                                              //     IconButton(
                                              //         onPressed: () {
                                              //           String data =
                                              //               inputController
                                              //                   .text;
                                              //           inputController.clear();
                                              //           _sendMessage(
                                              //               channelId: state[
                                              //                   widget.roomId]!,
                                              //               context: context,
                                              //               content:
                                              //                   data.trim());
                                              //         },
                                              //         icon: Icon(Icons.send))
                                              //   ],
                                              // ),
                                            ]);
                                      },
                                    ),
                                  );
                                } else if (roomChatsnapshot.hasError) {
                                  print(roomChatsnapshot.error);
                                  return SnackBar(
                                      content: Text(
                                          'Error has occured while reading from DB'));
                                }
                                return Container();
                              }),
                      drawer: SafeArea(
                        child: Drawer(
                          // child: Row(
                          //   children: [
                          //     Expanded(
                          //       flex: 13,
                          // constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width*0.3),
                          // child: Column(
                          //   // padding: EdgeInsets.zero,
                          //   children: [
                          //     Row(
                          //       children: [
                          //         Expanded(
                          //           flex: 2,
                          //           child: Container(
                          //             // width: 50,
                          //             child: IconButton(
                          //                 padding: EdgeInsets.all(2),
                          //                 icon: Icon(Icons.home, size: 30),
                          //                 onPressed: () => Navigator.of(context)
                          //                     .pushReplacementNamed('/')),
                          //           ),
                          //         ),
                          //         // VerticalDivider(color: Colors.grey, width: 2),
                          //         Expanded(
                          //             flex: 8, child: Text(widget.roomName))
                          //       ],
                          //     ),
                          //     Divider(),
                          //     Row(
                          //       children: [
                          //         Expanded(flex: 2, child: RoomListView()),
                          //         // VerticalDivider(color: Colors.grey, width: 2),
                          //         Expanded(
                          //             flex: 8,
                          //             child: channelsView(
                          //               roomId: widget.roomId,
                          //             ))
                          //       ],
                          //     ),
                          //   ],
                          // ),
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
                                            padding: EdgeInsets.all(2),
                                            icon: Icon(Icons.home, size: 30),
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pushReplacementNamed('/')),
                                      ),
                                    ),
                                    // VerticalDivider(color: Colors.grey, width: 2),
                                    Expanded(
                                        flex: 8, child: Text(widget.roomName))
                                  ],
                                ),
                              ),
                              body: Row(
                                children: [
                                  Expanded(flex: 2, child: RoomListView()),
                                  // VerticalDivider(color: Colors.grey, width: 2),
                                  Expanded(
                                      flex: 8,
                                      child: channelsView(
                                        roomId: widget.roomId,
                                      ))
                                ],
                              )),
                        ),
                      ),
                      endDrawer: Drawer(child: Container(color: Colors.lime)),
                      // offset: IDOffset.only(right: 0, left: 0.3),
                    );
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

class channelsView extends StatefulWidget {
  final _channels = <channelsTile>[];
  late final String roomId;
  late final String currChannelID;
  get tiles => _channels;

  channelsView({
    required this.roomId,
  });

  @override
  channelsViewState createState() => channelsViewState();
}

class channelsViewState extends State<channelsView> {
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: RepositoryProvider.of<AppDb>(context)
            .getChannelsOfRoom(roomID: widget.roomId)
            .watch(),
        builder:
            (BuildContext context, AsyncSnapshot<List<RoomsChannel>> snapshot) {
          if (snapshot.hasData) {
            return ListView(
                children: snapshot.data!
                    .map((e) => channelsTile(
                        roomId: widget.roomId,
                        channelId: e.channelId,
                        name: e.channelName))
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

class channelsTile extends StatefulWidget {
  late final String channelId;
  late final String name;
  late final String roomId;
  late final bool? _unread;

  channelsTile({
    required this.roomId,
    required this.channelId,
    required this.name,
    bool? unread,
  }) {
    _unread = unread;
  }

  @override
  channelsTileState createState() => channelsTileState(unread: _unread);
}

class channelsTileState extends State<channelsTile> {
  bool _unread = false;

  channelsTileState({
    bool? unread,
  }) {
    _unread = unread ?? (Random().nextInt(2) == 0 ? false : true);
    // _unread = true;
  }
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 5,
      // leading: Text("#"),
      onTap: () => {
        Navigator.of(context).pop(),
        BlocProvider.of<RoomsCubit>(context, listen: false)
            .updateDefaultChannel(widget.roomId, widget.channelId)
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
