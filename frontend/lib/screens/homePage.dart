import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:provider/provider.dart';
import 'package:yaroom/blocs/activeStatus.dart';
import 'package:yaroom/blocs/rooms.dart';
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
      }
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
                                            onPressed: () => {},
                                            tooltip: "Pinned Messages",
                                            icon: Icon(Icons.push_pin)),
                                        Text("Pins")
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
                                    )
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
                                          return ViewContact(e);
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

  Widget addChannel() {
    var ChannelController = TextEditingController();
    return AlertDialog(
      scrollable: true,
      title: Text('Add Channel'),
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: ChannelController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  icon: Icon(Icons.create),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
            child: Text("Submit"),
            onPressed: () {
              if (ChannelController.text != '') {}
            }),
      ],
    );
  }

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
                              await Provider.of<AuthorizationService>(context,
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
                          await Navigator.of(context)
                              .pushNamedAndRemoveUntil('/signin', (_) => false);
                        },
                        icon: Icon(Icons.logout),
                        tooltip: 'Log Out',
                      ),
                    ),
                    IconButton(
                        onPressed: () async {
                          await Navigator.of(context).pushNamed("/settings");
                        },
                        icon: Icon(Icons.settings))
                  ],
                ),
          drawer: currentIndex == 0
              ? Drawer(
                  child: Row(
                    children: [
                      Expanded(flex: 15, child: RoomListView()),
                      Expanded(
                        flex: 90,
                        child: (roomflag == false
                            ? SelectRoomPage()
                            : ChannelsView(
                                roomId: roomId!,
                              )),
                      ),
                      Expanded(
                        child: ListTile(
                          minVerticalPadding: 5,
                          leading: Text("+"),
                          title: Text("Add Channel"),
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return addChannel();
                                });
                          },
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
    });
  }
}
