import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:yaroom/blocs/roomMetadata.dart';
import './utils/connectivity.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaroom/blocs/activeStatus.dart';
import 'package:yaroom/blocs/chatMeta.dart';
import 'package:yaroom/blocs/fcmToken.dart';
import 'package:yaroom/blocs/rooms.dart';
import 'utils/router.dart';
import 'moor/db.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'utils/types.dart';
import 'utils/notifiers.dart';
import 'utils/activeStatus.dart';
import 'utils/fcmToken.dart';
import 'utils/messageExchange.dart';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'utils/secureStorageService.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'utils/authorizationService.dart';
import 'moor/utils.dart';
import 'utils/fetchBackendData.dart';
import 'blocs/groupMetadata.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'blocs/friendRequestsData.dart';
import 'package:moor/moor.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  moorRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  AppDb db = constructDb(logStatements: true);
  print("Handling a background message: ${message.messageId}");
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationDocumentsDirectory(),
  );
  Map<String, dynamic> data = message.data;
  var chatMeta = ChatMetaCubit();
  await updateDb(db, data, chatMeta);
}

Future<void> main() async {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  WidgetsFlutterBinding.ensureInitialized();
  moorRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  AppDb db = constructDb(logStatements: true);
  await Firebase.initializeApp();

  String? fcmToken = await FirebaseMessaging.instance.getToken(
      vapidKey:
          'BAk6SShjzB8D0LkNQQzCtxwCVQnIBLVx1Eedl-WpcSi1bNTPGTPfzp-YLaL-ob9Md1mv7qgy0F71mdg2mVZRIV8');
  print("Got fcm token, $fcmToken");
  FcmTokenCubit fcmTokenCubit = FcmTokenCubit();
  fcmTokenCubit.updateToken(fcmToken!);
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    fcmTokenCubit.updateToken(newToken);
  });

  // TODO Web implementation not done yet
  // For web we need to handle background messages via javascript
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  foregroundNotifSelect = StreamController.broadcast();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onSelectNotification: (String? payload) async {
    print("--------------SELECTED NOTIF--------------\n");
    print("$payload\n");
    if (payload != null) {
      foregroundNotifSelect?.sink.add(payload);
    }
  });

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationDocumentsDirectory(),
  );

  var activeStatus = ActiveStatusMap(statusMap: Map());
  var chatMeta = ChatMetaCubit();
  var msgStream = MessageExchangeStream();
  var groupMetadataCubit =
      GroupMetadataCubit(initialState: GroupMetadataMap(Map()));
  var roomMetadataCubit =
      RoomMetadataCubit(initialState: RoomMetadataMap(Map()));
  var friendRequestsCubit =
      FriendRequestCubit(initialState: FriendRequestDataMap(Map()));
  msgStream.stream.listen((encodedData) async {
    print("Got encoded data::::::\n" + encodedData);
    if (encodedData == "" ||
        encodedData == "null" ||
        encodedData == "true" ||
        encodedData == "false") return;
    var data = jsonDecode(encodedData) as Map;
    if (data.containsKey('error')) {
      print("WS stream returned error ${data['error']}");
      return;
    } else if (data.containsKey('active')) {
      activeStatus.add(data['userId']);
      activeStatus.update(data['userId'], data['active']);
      print(
          "Active status recieved for ${data['userId']} as ${data['active']}");
      return;
    } else if (data.containsKey('update')) {
      if (data['update'] == 'group') {
        await db.createGroup(
            groupId: data["Groupid"],
            name: data["Name"],
            description: data["Description"]);
        if (data["Userslist"] != null) {
          for (var user in data["Userslist"]) {
            await db.addUser(
                userId: user["userId"],
                name: user["name"],
                about: user["about"]);
            await db.addUserToGroup(
                groupId: data["Groupid"], userId: user["userId"]);
          }
        }
        if (data.containsKey('delUser')) {
          await db.removeUserFromGroup(
              userId: data['delUser'], groupId: data["Groupid"]);
        }
        var groupMembers =
            await db.getGroupMembers(groupID: data["Groupid"]).get();
        var d = GroupMetadata(
            groupId: data["Groupid"],
            name: data["Name"],
            description:
                data["Description"] == null ? "" : data["Description"]!,
            groupMembers: groupMembers);
        groupMetadataCubit.update(d);
        print("added group ${data["Groupid"]} to cubit");
        var get = groupMetadataCubit.state.data[data["Groupid"]];
        print("after update, name: ${get?.name}, desc: ${get?.description}");
      } else if (data['update'] == 'room') {
        await db.createRoom(
            roomId: data["Roomid"],
            name: data["Name"],
            description: data["Description"]);
        if (data["Userslist"] != null) {
          for (var user in data["Userslist"]) {
            await db.addUserToRoom(
                roomsId: data["Roomid"], userId: user["userId"]);
          }
        }
        if (data.containsKey('delUser')) {
          await db.removeUserFromRoom(
              userId: data['delUser'], roomId: data["Roomid"]);
        }
        if (data.containsKey('delChannel')) {
          await db.deleteChannelFromRoom(
              roomId: data['Roomid'], channelId: data["delChannel"]);
        }
        var roomChannels = new Map<String, String>();
        if (data["Channelslist"] != null) {
          for (var channel in data["Channelslist"].keys) {
            await db.addChannelsToRoom(
                roomId: data["Roomid"],
                channelId: channel,
                channelName: data["Channelslist"][channel]);
          }
        }
        var roomChannelsList =
            await db.getChannelsOfRoom(roomID: data["Roomid"]).get();
        for (var channel in roomChannelsList) {
          roomChannels[channel.channelId] = channel.channelName;
        }
        var roomMembers = await db.getRoomMembers(roomID: data["Roomid"]).get();
        var d = RoomMetadata(
            roomId: data["Roomid"],
            name: data["Name"],
            description:
                data["Description"] == null ? "" : data["Description"]!,
            roomMembers: roomMembers,
            roomChannels: roomChannels);
        roomMetadataCubit.update(d);
        print("added room ${data["Roomid"]} to cubit");
        var get = roomMetadataCubit.state.data[data["Roomid"]];
        print("after update, name: ${get?.name}, desc: ${get?.description}");
      }
      print("update type");
      return;
    } else if (data.containsKey("exit")) {
      if (data['exit'] == 'group') {
        await db.removeUserFromGroup(
            groupId: data["Groupid"], userId: data["delUser"]);
        groupMetadataCubit.delete(data["Groupid"]);
        await db.deleteGroup(groupId: data["Groupid"]);
      }
      if (data['exit'] == 'room') {
        await db.removeUserFromGroup(
            groupId: data["Roomid"], userId: data["delUser"]);
        groupMetadataCubit.delete(data["Roomid"]);
        await db.deleteRoom(roomId: data["Roomid"]);
      }
      print("exit type");
      return;
    } else if (data.containsKey("friendRequest")) {
      var fromUser = jsonDecode(data["fromUser"]);
      await db.addUser(
          userId: fromUser["Userid"],
          name: fromUser["Name"],
          about: fromUser["About"]);
      await db.addNewFriendRequest(
          userId: fromUser["Userid"], status: int.parse(data["friendRequest"]));
      friendRequestsCubit.update(FriendRequestData(
          userId: fromUser["Userid"],
          name: fromUser["Name"],
          status: int.parse(data["friendRequest"]),
          about: fromUser["About"]));
    } else if (data.containsKey("type")) {
      await updateDb(db, data, chatMeta);
    }
  }, onError: (e) {
    print("WS stream returned error $e");
  });
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print(message.data);
    msgStream.addStreamMessage(message.data);
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    // If `onMessage` is triggered with a notification, construct our own
    // local notification to show to users using the created channel.
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(channel.id, channel.name,
                channelDescription: channel.description, tag: android.tag),
          ),
          payload: jsonEncode(message.data));
    }
  });

  const FlutterSecureStorage secureStorage = FlutterSecureStorage();
  final SecureStorageService secureStorageService =
      SecureStorageService(secureStorage);

  runApp(MyApp(
      db: db,
      msgExchangeStream: msgStream,
      secureStorageService: secureStorageService,
      fcmTokenCubit: fcmTokenCubit,
      activeStatus: activeStatus,
      chatMetaCubit: chatMeta,
      roomMetadataCubit: roomMetadataCubit,
      friendRequestCubit: friendRequestsCubit,
      groupMetadataCubit: groupMetadataCubit));
}

class MyApp extends StatelessWidget {
  late final AppDb db;
  late final MessageExchangeStream msgExchangeStream;
  late final SecureStorageService secureStorageService;
  late final FcmTokenCubit fcmTokenCubit;
  late final ActiveStatusMap activeStatus;
  late final ChatMetaCubit chatMetaCubit;
  late final GroupMetadataCubit groupMetadataCubit;
  late final RoomMetadataCubit roomMetadataCubit;
  late final FriendRequestCubit friendRequestCubit;
  MyApp(
      {required this.db,
      required this.msgExchangeStream,
      required this.secureStorageService,
      required this.fcmTokenCubit,
      required this.activeStatus,
      required this.chatMetaCubit,
      required this.groupMetadataCubit,
      required this.friendRequestCubit,
      required this.roomMetadataCubit});

  Future<String> getInitialRoute(BuildContext context) async {
    await Future.delayed(Duration(milliseconds: 500));
    final String? idToken = await secureStorageService.getIdToken();
    if (idToken != null && idToken.isNotEmpty) {
      // Start web socket
      String? accessToken =
          await Provider.of<AuthorizationService>(context, listen: false)
              .getValidAccessToken();
      if (accessToken == null) {
        return Future.value('/signin');
      }
      await Provider.of<AppDb>(context, listen: false).deleteAll();
      await Provider.of<AppDb>(context, listen: false).createAll();
      msgExchangeStream.start('ws://localhost:8884/v1/ws', accessToken);

      // Handle refresh token update
      notifyFCMToken(fcmTokenCubit, accessToken);

      //setting user active
      final userid =
          await Provider.of<AuthorizationService>(context, listen: false)
              .getUserId();
      Provider.of<ActiveStatusMap>(context, listen: false).add(userid);
      Provider.of<ActiveStatusMap>(context, listen: false).update(userid, true);
      // Backend hanldes user new case :)
      // visit route `getUserDetails`
      await fetchUserDetails(
          accessToken, parseIdToken(idToken)["name"], context);
      // This must be before fetch is called
      Map<String, String> lastMsgRead = Map();
      try {
        var response = await http.get(Uri.parse('$BACKEND_URL/v1/lastRead'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': "Bearer $accessToken",
            });
        print("Last read response ${response.statusCode} ${response.body}");
        List<dynamic> result = jsonDecode(response.body);
        result.forEach((mp) {
          lastMsgRead[mp['exchangeId']!] = mp['lastRead']!;
        });
      } catch (e) {
        print("Exception occured while getting last read - $e");
      }
      Provider.of<ChatMetaCubit>(context, listen: false)
          .setUser(userid, lastMsgRead);
      print(accessToken);
      await Future.delayed(Duration(seconds: 2), () async {
        var groups = await RepositoryProvider.of<AppDb>(context, listen: false)
            .getGroupsMetadata()
            .get();
        for (var group in groups) {
          var groupMembers =
              await RepositoryProvider.of<AppDb>(context, listen: false)
                  .getGroupMembers(groupID: group.groupId)
                  .get();
          var d = GroupMetadata(
              groupId: group.groupId,
              name: group.name,
              description: group.description == null ? "" : group.description!,
              groupMembers: groupMembers);
          Provider.of<GroupMetadataCubit>(context, listen: false).update(d);
          print("added group ${group.groupId} to cubit");
        }
      });
      await Future.delayed(Duration(seconds: 2), () async {
        var rooms = await RepositoryProvider.of<AppDb>(context, listen: false)
            .getRoomsMetadata()
            .get();
        for (var room in rooms) {
          var roomMembers =
              await RepositoryProvider.of<AppDb>(context, listen: false)
                  .getRoomMembers(roomID: room.roomId)
                  .get();
          var roomChannels = new Map<String, String>();
          var channelList =
              await RepositoryProvider.of<AppDb>(context, listen: false)
                  .getChannelsOfRoom(roomID: room.roomId)
                  .get();
          for (var channel in channelList) {
            roomChannels[channel.channelId] = channel.channelName;
          }
          var d = RoomMetadata(
              roomId: room.roomId,
              name: room.name,
              description: room.description == null ? "" : room.description!,
              roomMembers: roomMembers,
              roomChannels: roomChannels);
          Provider.of<RoomMetadataCubit>(context, listen: false).update(d);
          print("added room ${room.roomId} to cubit");
        }
      });
      var friendRequests =
          await RepositoryProvider.of<AppDb>(context, listen: false)
              .getFriendRequests()
              .get();
      for (var friendRequest in friendRequests) {
        var d = FriendRequestData(
            userId: friendRequest.userId,
            name: friendRequest.name,
            about: friendRequest.about == null ? "" : friendRequest.about!,
            status: friendRequest.status == null ? 0 : friendRequest.status!);
        Provider.of<FriendRequestCubit>(context, listen: false).update(d);
        print(
            "added friend request ${friendRequest.name} with status ${friendRequest.status} to the cubit");
      }
      // visit route `getLaterMessages`
      await fetchLaterMessages(accessToken, null, context);
      return Future.value('/');
    }
    return Future.value('/signin');
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          Provider<ActiveStatusMap>.value(value: activeStatus),
          Provider<FlutterAppAuth>(
            create: (_) => FlutterAppAuth(),
          ),
          ProxyProvider<FlutterAppAuth, AuthorizationService>(
            update: (_, FlutterAppAuth appAuth, __) =>
                AuthorizationService(appAuth, secureStorageService),
          ),
          ChangeNotifierProvider<LandingViewModel>(
              create: (BuildContext context) => LandingViewModel(
                    Provider.of<AuthorizationService>(context, listen: false),
                  )),
          BlocProvider<RoomsCubit>(create: (_) => RoomsCubit()),
          BlocProvider<GroupMetadataCubit>(create: (_) => groupMetadataCubit),
          BlocProvider<RoomMetadataCubit>(create: (_) => roomMetadataCubit),
          BlocProvider<FriendRequestCubit>(create: (_) => friendRequestCubit),
          RepositoryProvider<AppDb>.value(value: db),
          Provider<MessageExchangeStream>.value(value: msgExchangeStream),
          BlocProvider<FcmTokenCubit>.value(value: fcmTokenCubit),
          BlocProvider<ChatMetaCubit>.value(value: chatMetaCubit),
          ChangeNotifierProvider<DMsList>(create: (_) => DMsList()),
          ChangeNotifierProvider<GroupsList>(
            create: (_) => GroupsList(),
          ),
          ChangeNotifierProvider<RoomList>(create: (_) => RoomList()),
          BlocProvider(create: (context) {
            return FilePickerCubit(
                initialState:
                    FilePickerDetails(media: Map(), filesAttached: 0));
          })
        ],
        child: ConnectivityCheck(
          connectionStream: msgExchangeStream.connected.stream,
          child: Builder(
            builder: (context) {
              return FutureBuilder<String>(
                future: getInitialRoute(context),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return MaterialAppWrapper(
                        initialRoute: snapshot.data!, ws: msgExchangeStream);
                  }
                  return LoadingBar;
                },
              );
            },
          ),
        ));
  }
}

class MaterialAppWrapper extends StatefulWidget {
  late final String initialRoute;
  late final ActiveStatusNotifier activityNotify;
  MaterialAppWrapper({required this.initialRoute, required ws}) {
    this.activityNotify = ActiveStatusNotifier(ws: ws);
  }

  @override
  _MaterialAppWrapperState createState() =>
      _MaterialAppWrapperState(activityNotify: this.activityNotify);
}

class _MaterialAppWrapperState extends State<MaterialAppWrapper>
    with WidgetsBindingObserver {
  late final ActiveStatusNotifier activityNotify;
  Timer? activeFuture;
  _MaterialAppWrapperState({required this.activityNotify});

  @override
  void initState() {
    // Handle refresh token update
    super.initState();
    activeFuture = Timer.periodic(Duration(seconds: 3), activityNotify.send);
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    activeFuture?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("Started sending active status!!!");
      activeFuture = Timer.periodic(Duration(seconds: 3), activityNotify.send);
    } else {
      if (activeFuture != null) {
        print("Stopped sending active status!!!");
        activeFuture!.cancel();
        activeFuture = null;
      }
    }
  }

  final _contentRouter = ContentRouter();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: widget.initialRoute,
      debugShowCheckedModeBanner: false,
      title: 'yaroom',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blueGrey[600],
        accentColor: Colors.grey[300],
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey[600],
        accentColor: Colors.black38,
      ),
      themeMode: ThemeMode.dark,
      onGenerateRoute: _contentRouter.onGenerateRoute,
    );
  }
}
