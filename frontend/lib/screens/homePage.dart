import 'dart:async';
import 'dart:convert';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:flutter/material.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:provider/provider.dart';
import 'package:yaroom/blocs/activeStatus.dart';
import 'package:yaroom/blocs/roomMetadata.dart';
import 'package:yaroom/blocs/friendRequestsData.dart';
import 'package:yaroom/blocs/rooms.dart';
import 'package:yaroom/utils/backendRequests.dart';
import 'components/searchDelegate.dart';
import 'package:yaroom/blocs/fcmToken.dart';
import 'package:yaroom/screens/components/contactView.dart';
import 'package:yaroom/utils/guidePages.dart';
import 'package:yaroom/utils/messageExchange.dart';
import 'package:yaroom/utils/types.dart';
import './messaging/chatsView.dart';
import './messaging/groupsView.dart';
import './rooms/channels.dart';
import './rooms/room.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './components/roomsList.dart';
import '../utils/authorizationService.dart';
import '../utils/fcmToken.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../screens/components/friendsView.dart';

class HomePage extends StatefulWidget {
  late final int initIndex;
  late final String? roomId;
  late final String? roomName;
  late final String? channelId;

  HomePage(HomePageArguments args) {
    if (args.index == 0) {
      this.roomId = args.roomId!;
      this.roomName = args.roomName!;
      this.channelId = args.channelId;
      this.initIndex = 0;
      return;
    }
    if (args.index == null) {
      initIndex = 1;
    } else {
      this.initIndex = args.index!;
    }
    this.roomId = null;
    this.roomName = null;
    this.channelId = null;
  }

  @override
  HomePageState createState() => HomePageState(currentIndex: initIndex);
}

class HomePageState extends State<HomePage> {
  late int currentIndex;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldkey = new GlobalKey();

  HomePageState({required this.currentIndex});

  Future<void> notificationInteractionHandler(
      Map<String, dynamic> content) async {
    print("Interaction handling for $content");
    if (content.containsKey('type')) {
      if (content['type'] == 'ChatMessage') {
        List<User> data = await RepositoryProvider.of<AppDb>(context)
            .getUserById(userId: content['fromUser'])
            .get();
        Navigator.pushNamed(context, '/chat',
            arguments:
                ChatPageArguments(userId: data[0].userId, name: data[0].name));
      } else if (content['type'] == 'GroupMessage') {
        List<GroupDM> data = await RepositoryProvider.of<AppDb>(context)
            .getGroupById(groupId: content['groupId'])
            .get();
        Navigator.pushNamed(context, '/groupchat',
            arguments: GroupChatPageArguments(groupId: data[0].groupId));
      } else if (content['type'] == 'RoomsMessage') {
        List<RoomsListData> data = await RepositoryProvider.of<AppDb>(context)
            .getRoomDetails(roomId: content['roomId'])
            .get();
        Navigator.pushNamed(context, '/room',
            arguments: RoomArguments(
                roomId: data[0].roomId,
                roomName: data[0].name,
                channelId: content['channelId']));
      }
    } else if (content.containsKey('friendRequest')) {
      // TO DO
    }
  }

  Future<void> foregroundNotifInteractions() async {
    foregroundNotifSelect?.stream.listen((String content) async {
      await notificationInteractionHandler(jsonDecode(content));
    });
  }

  Future<void> backgroundNotifInteractions() async {
    // Get any messages which caused the application to open from a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await notificationInteractionHandler(initialMessage.data);
    }

    // Handle any interaction when the app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await notificationInteractionHandler(message.data);
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
    backgroundNotifInteractions();
    foregroundNotifInteractions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _getRoomTitle(BuildContext context, String roomId, String? channelId) {
    return FutureBuilder(
        future: RepositoryProvider.of<AppDb>(context)
            .getChannelName(roomId: roomId, channelId: channelId!)
            .get(),
        builder:
            (BuildContext context, AsyncSnapshot<List<RoomsChannel>> snapshot) {
          if (snapshot.hasData) {
            return ListTile(
              // leading: Text("#"),
              title: Text(
                "# " + snapshot.data![0].channelName,
                style: TextStyle(fontSize: 20),
              ),
            );
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return SnackBar(
                content: Text('Error has occured while reading from DB'));
          }
          return Container();
        });
  }

  AppBar _getRoomAppBar(
      BuildContext context, String roomId, String? channelId) {
    return AppBar(
      titleSpacing: 0,
      leading: FutureBuilder(
        future: RepositoryProvider.of<AppDb>(context)
            .getRoomDetails(roomId: roomId)
            .get(),
        builder: (BuildContext context,
            AsyncSnapshot<List<RoomsListData>> snapshot) {
          if (snapshot.hasData) {
            return IconButton(
                icon: CircleAvatar(
                    backgroundColor: Colors.grey[350],
                    foregroundImage:
                        iconImageWrapper(snapshot.data![0].roomId)),
                onPressed: () => Scaffold.of(context).openDrawer());
          }
          return IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: Icon(Icons.list));
        },
      ),
      title: channelId == null
          ? Text("Pick a channel")
          : _getRoomTitle(context, roomId, channelId),
      actions: channelId == null
          ? []
          : <Widget>[
              IconButton(
                onPressed: () => {
                  showSearch(
                      context: context,
                      delegate: ExchangeSearchDelegate(
                          exchangeId: roomId + "@" + channelId,
                          msgType: "RoomMessage",
                          limit: 100))
                },
                icon: Icon(Icons.search),
                tooltip: 'Search',
              ),
              IconButton(
                onPressed: () => {_scaffoldkey.currentState!.openEndDrawer()},
                icon: Icon(Icons.more_vert),
                tooltip: 'More',
              )
            ],
    );
  }

  _getEndDrawer(BuildContext context, String? roomId) {
    return FutureBuilder(
        future: RepositoryProvider.of<AppDb>(context)
            .getRoomMembers(roomID: roomId!)
            .get(),
        builder: (BuildContext context,
            AsyncSnapshot<List<User>> roomMembersSnapshot) {
          if (roomMembersSnapshot.hasData) {
            return StreamBuilder(
                stream: RepositoryProvider.of<AppDb>(context)
                    .getRoomDetails(roomId: roomId)
                    .watch(),
                builder: (BuildContext context,
                    AsyncSnapshot<List<RoomsListData>> Roomsnapshot) {
                  if (Roomsnapshot.hasData) {
                    // roomMembersSnapshot.data!.map((e) =>
                    //     Provider.of<ActiveStatusMap>(context, listen: false)
                    //         .add(e.userId));
                    return Drawer(
                      child: ListView(padding: EdgeInsets.zero, children: [
                        DrawerHeader(
                            child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                              ListTile(
                                tileColor: Colors.transparent,
                                title: Text(Roomsnapshot.data![0].name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 20)),
                              ),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        IconButton(
                                            onPressed: () => {
                                                  Navigator
                                                      .pushReplacementNamed(
                                                          context, '/editroom',
                                                          arguments: {
                                                        "roomId": roomId
                                                      })
                                                },
                                            tooltip: "Edit Room",
                                            icon: Icon(Icons.edit)),
                                        Text("Edit")
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                            onPressed: () => {},
                                            tooltip: "Search",
                                            icon: Icon(Icons.search)),
                                        Text("Search")
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                            onPressed: () => {
                                                  showDialog(
                                                      context: context,
                                                      builder: (_) {
                                                        return AlertDialog(
                                                            title: Text(
                                                                "Exit Room"),
                                                            content: Text(
                                                                "Are you sure you want to exit the room? The related chat will no longer be displayed to you."),
                                                            actions: [
                                                              TextButton(
                                                                  onPressed:
                                                                      () async {
                                                                    // request to backend to remove user from group
                                                                    await exitRoom(
                                                                        roomId,
                                                                        context);
                                                                    await Navigator
                                                                        .pushReplacementNamed(
                                                                            context,
                                                                            '/');
                                                                  },
                                                                  child: Text(
                                                                      "Yes")),
                                                              TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          context),
                                                                  child: Text(
                                                                      "No"))
                                                            ]);
                                                      })
                                                },
                                            tooltip: "Exit Room",
                                            icon: Icon(Icons.exit_to_app)),
                                        Text("Exit")
                                      ],
                                    ),
                                  ])
                            ])),
                        ...roomMembersSnapshot.data!.map((User e) =>
                            BlocBuilder<ActiveStatusCubit, bool>(
                              bloc: Provider.of<ActiveStatusMap>(context)
                                  .get(e.userId),
                              builder: (context, state) {
                                return ListTile(
                                    onTap: () => showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext c) {
                                          return BlocBuilder<FriendRequestCubit,
                                                  FriendRequestDataMap>(
                                              bloc: Provider.of<
                                                      FriendRequestCubit>(
                                                  context,
                                                  listen: false),
                                              builder: (context, state) {
                                                if (state.data
                                                    .containsKey(e.userId)) {
                                                  return ViewContact(
                                                      state.data[e.userId]!);
                                                } else {
                                                  return ViewContact(
                                                      FriendRequestData(
                                                          userId: e.userId,
                                                          name: e.name,
                                                          about: e.about == null
                                                              ? ""
                                                              : e.about!,
                                                          status: -1));
                                                }
                                              });
                                        }),
                                    tileColor: Colors.transparent,
                                    leading: Stack(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.grey[350],
                                          foregroundImage:
                                              iconImageWrapper(e.userId),
                                        ),
                                        Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                                width: 15,
                                                height: 15,
                                                decoration: new BoxDecoration(
                                                  color: state
                                                      ? Colors.green
                                                      : Colors.grey,
                                                  shape: BoxShape.circle,
                                                )))
                                      ],
                                    ),
                                    title: Text(
                                      e.name,
                                    ));
                              },
                            ))
                      ]),
                    );
                  } else if (Roomsnapshot.hasError) {
                    print(Roomsnapshot.error);
                    return SnackBar(
                        content:
                            Text('Error has occured while reading from DB'));
                  }
                  return Container();
                });
          } else if (roomMembersSnapshot.hasError) {
            print(roomMembersSnapshot.error);
            return SnackBar(
                content: Text('Error has occured while reading from local DB'));
          }
          return CircularProgressIndicator();
        });
  }

  // Widget addChannel() {
  //   var ChannelController = TextEditingController();
  //   // return BlocBuilder<RoomMetadataCubit, RoomMetadataMap>(
  //   //   builder: (context, state) {
  //   return AlertDialog(
  //     scrollable: true,
  //     title: Text('Add Channel'),
  //     content: Padding(
  //       padding: const EdgeInsets.all(8.0),
  //       child: Form(
  //         child: Column(
  //           children: <Widget>[
  //             TextFormField(
  //               controller: ChannelController,
  //               decoration: InputDecoration(
  //                 labelText: 'Name',
  //                 icon: Icon(Icons.create),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //     actions: [
  //       ElevatedButton(
  //           child: Text("Submit"),
  //           onPressed: () async {
  //             if (ChannelController.text != '') {
  //               var newRoomChannels =
  //                   state.data[this.widget.roomId]!.roomChannels;
  //               newRoomChannels[""] = ChannelController.text;
  //               await editRoom(
  //                   jsonEncode(<String, dynamic>{
  //                     "roomId": this.widget.roomId,
  //                     "name": state.data[this.widget.roomId]!.name,
  //                     "description":
  //                         state.data[this.widget.roomId]!.description,
  //                     "roomMembers":
  //                         state.data[this.widget.roomId]!.roomMembers,
  //                     "channelsList":
  //                         state.data[this.widget.data["roomId"]]!.roomChannels
  //                   }),
  //                   context);
  //             }
  //           }),
  //     ],
  //   );
  //   //   },
  //   // );
  // }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomsCubit, RoomsState>(
        builder: (BuildContext context, RoomsState state) {
      String? roomId = widget.roomId;
      bool roomflag = true;
      if (roomId == null) {
        if (state.lastActive == null) {
          roomflag = false;
        } else {
          roomId = state.lastActive!.roomId;
        }
      }
      String? channelId = state.lastOpened.containsKey(roomId)
          ? state.lastOpened[roomId]
          : null;

      return BlocBuilder<RoomMetadataCubit, RoomMetadataMap>(
        builder: (context, metastate) {
          return SafeArea(
            child: Scaffold(
              key: _scaffoldkey,
              appBar: currentIndex == 0
                  ? (PreferredSize(
                      child: roomId == null
                          ? AppBar()
                          : _getRoomAppBar(context, roomId, channelId),
                      preferredSize: Size.fromHeight(kToolbarHeight)))
                  : AppBar(
                      automaticallyImplyLeading: false,
                      actions: [
                        Builder(
                          builder: (context) => IconButton(
                            onPressed: () async {
                              // Invalidate fcm token
                              final String? accessToken =
                                  await Provider.of<AuthorizationService>(
                                          context,
                                          listen: false)
                                      .getValidAccessToken();
                              await invalidateFCMToken(
                                  BlocProvider.of<FcmTokenCubit>(context,
                                      listen: false),
                                  accessToken!);
                              // Logout
                              await Provider.of<AuthorizationService>(context,
                                      listen: false)
                                  .logout(context);
                              // Clear DB
                              await Provider.of<AppDb>(context, listen: false)
                                  .deleteAll();
                              await Provider.of<AppDb>(context, listen: false)
                                  .createAll();
                              // Close websocket
                              Provider.of<MessageExchangeStream>(context,
                                      listen: false)
                                  .close();
                              HydratedBloc.storage.clear();
                              await Navigator.of(context)
                                  .pushNamedAndRemoveUntil(
                                      '/signin', (_) => false);
                            },
                            icon: Icon(Icons.logout),
                            tooltip: 'Log Out',
                          ),
                        ),
                        IconButton(
                            onPressed: () async {
                              await Navigator.of(context)
                                  .pushNamed("/settings");
                            },
                            icon: Icon(Icons.settings))
                      ],
                    ),
              drawer: currentIndex == 0
                  ? Drawer(
                      child: Row(
                        children: [
                          Expanded(
                              flex: 15,
                              child: Column(
                                children: [
                                  Expanded(child: RoomListView()),
                                  Column(children: [
                                    CircleAvatar(
                                        backgroundColor: Colors.grey[350],
                                        foregroundImage:
                                            AssetImage("assets/yaroom.png"),
                                        radius: 27.0,
                                        child: IconButton(
                                            onPressed: () =>
                                                Navigator.of(context).pushNamed(
                                                    "/editroom",
                                                    arguments: {"roomId": ""}),
                                            icon: Icon(Icons.add))),
                                    SizedBox(
                                      height: 6,
                                    )
                                  ]),
                                ],
                              )),
                          Expanded(
                            flex: 90,
                            child: Column(
                              children: [
                                Expanded(
                                  // flex: 90,
                                  child: (roomflag == false
                                      ? SelectRoomPage()
                                      : ChannelsView(
                                          roomId: roomId!,
                                        )),
                                ),
                                // Expanded(
                                //   child:
                                ListTile(
                                  minVerticalPadding: 5,
                                  leading: Text("+"),
                                  title: Text("Add Channel"),
                                  onTap: () {
                                    BuildContext dialogContext;
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          var ChannelController =
                                              TextEditingController();
                                          dialogContext = context;
                                          return AlertDialog(
                                            scrollable: true,
                                            title: Text('Add Channel'),
                                            content: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Form(
                                                child: Column(
                                                  children: <Widget>[
                                                    TextFormField(
                                                      controller:
                                                          ChannelController,
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: 'Name',
                                                        icon:
                                                            Icon(Icons.create),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            actions: [
                                              ElevatedButton(
                                                  child: Text("Submit"),
                                                  onPressed: () async {
                                                    if (ChannelController
                                                            .text !=
                                                        '') {
                                                      var newRoomChannels =
                                                          metastate
                                                              .data[roomId]!
                                                              .roomChannels;
                                                      newRoomChannels[""] =
                                                          ChannelController
                                                              .text;

                                                      var res = await editRoom(
                                                          jsonEncode(<String,
                                                              dynamic>{
                                                            "roomId": roomId,
                                                            "name": metastate
                                                                .data[roomId]!
                                                                .name,
                                                            "description":
                                                                metastate
                                                                    .data[
                                                                        roomId]!
                                                                    .description,
                                                            "roomMembers":
                                                                metastate
                                                                    .data[
                                                                        roomId]!
                                                                    .roomMembers
                                                                    .map((e) =>
                                                                        e.userId)
                                                                    .toList(),
                                                            "channelsList":
                                                                newRoomChannels
                                                          }),
                                                          context);
                                                      if (res == null) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .clearSnackBars();
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                              content: Text(
                                                                  'Channel Create Failed, try again!')),
                                                        );
                                                        return;
                                                      }
                                                      Navigator.pop(
                                                          dialogContext);
                                                    }
                                                  }),
                                            ],
                                          );
                                        });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
              endDrawer: currentIndex == 0
                  ? (roomflag == false
                      ? (SelectRoomPage())
                      : _getEndDrawer(context, roomId))
                  : null,
              body: SizedBox.expand(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => currentIndex = index);
                  },
                  children: <Widget>[
                    roomflag == false
                        ? SelectRoomPage()
                        : Room(roomId: roomId!, channelId: channelId),
                    ChatView(),
                    GroupChatView(),
                    FriendsView(),
                  ],
                ),
              ),
              bottomNavigationBar: BottomNavyBar(
                  selectedIndex: currentIndex,
                  onItemSelected: (index) {
                    setState(() => currentIndex = index);
                    _pageController.jumpToPage(index);
                  },
                  items: <BottomNavyBarItem>[
                    BottomNavyBarItem(
                        title: Text('Rooms'),
                        icon: CircleAvatar(
                            radius: 15,
                            foregroundImage: AssetImage("assets/yaroom.png"))),
                    BottomNavyBarItem(
                        title: Text('Messages'), icon: Icon(Icons.chat_bubble)),
                    BottomNavyBarItem(
                        title: Text('Groups'), icon: Icon(Icons.group)),
                    BottomNavyBarItem(
                        title: Text('Friends'), icon: Icon(Icons.person)),
                  ]),
            ),
          );
        },
      );
    });
  }
}
