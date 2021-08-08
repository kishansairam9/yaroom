import 'package:flutter/material.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:provider/provider.dart';
import 'package:yaroom/blocs/rooms.dart';
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
  late final String? roomIcon;
  late final String? channelId;

  HomePage(HomePageArguments args) {
    if (args.index == null) {
      initIndex = 1;
      this.roomId = null;
      this.roomName = null;
      this.roomIcon = null;
      this.channelId = null;
      return;
    }
    if (args.index == 0) {
      this.roomId = args.roomId!;
      this.roomName = args.roomName!;
      this.roomIcon = args.roomIcon!;
      this.channelId = args.channelId;
    }
    this.initIndex = args.index!;
  }

  @override
  HomePageState createState() => HomePageState(currentIndex: initIndex);
}

class HomePageState extends State<HomePage> {
  late int currentIndex;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldkey = new GlobalKey();

  HomePageState({required this.currentIndex});

  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null &&
        initialMessage.data['type'] == 'ChatMessage') {
      List<User> data = await RepositoryProvider.of<AppDb>(context)
          .getUserById(userId: initialMessage.data['fromUser'])
          .get();
      Navigator.pushNamed(context, '/chat',
          arguments: ChatPageArguments(
              userId: data[0].userId,
              name: data[0].name,
              image: data[0].profileImg));
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (message.data['type'] == 'ChatMessage') {
        List<User> data = await RepositoryProvider.of<AppDb>(context)
            .getUserById(userId: message.data['fromUser'])
            .get();
        Navigator.pushNamed(context, '/chat',
            arguments: ChatPageArguments(
                userId: data[0].userId,
                name: data[0].name,
                image: data[0].profileImg));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
    setupInteractedMessage();
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
                  foregroundImage: snapshot.data![0].roomIcon == null
                      ? null
                      : NetworkImage('${snapshot.data![0].roomIcon!}'),
                  backgroundImage: AssetImage('assets/no-profile.png'),
                ),
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
      actions: <Widget>[
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
                        ...roomMembersSnapshot.data!.map((User e) => ListTile(
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
                                      NetworkImage('${e.profileImg}'),
                                  backgroundImage:
                                      AssetImage('assets/no-profile.png'),
                                ),
                                Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                        width: 15,
                                        height: 15,
                                        decoration: new BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        )))
                              ],
                            ),
                            title: Text(
                              e.name,
                            )))
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
                          // Close websocket
                          Provider.of<MessageExchangeStream>(context,
                                  listen: false)
                              .close();

                          // Logout
                          await Provider.of<AuthorizationService>(context,
                                  listen: false)
                              .logout(context);

                          await Navigator.of(context)
                              .pushNamedAndRemoveUntil('/signin', (_) => false);
                        },
                        icon: Icon(Icons.logout),
                        tooltip: 'Log Out',
                      ),
                    ),
                    IconButton(
                        onPressed: () => {}, icon: Icon(Icons.fingerprint))
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