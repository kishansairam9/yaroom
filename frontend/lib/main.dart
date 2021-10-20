import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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

bool removeExistingDB = true;

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'Yaroom Notifications', // title
  description: 'Channel used for messaging notifications', // description
  importance: Importance.max,
);

AppDb db = constructDb(logStatements: true, removeExisting: removeExistingDB);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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

  foregroundNotifSelect = StreamController();

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
            await db.addUser(userId: user["userId"], name: user["name"]);
            await db.addUserToGroup(
                groupId: data["Groupid"], userId: user["userId"]);
          }
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
      print("exit type");
      return;
    }
    await updateDb(db, data, chatMeta);
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
  MyApp(
      {required this.db,
      required this.msgExchangeStream,
      required this.secureStorageService,
      required this.fcmTokenCubit,
      required this.activeStatus,
      required this.chatMetaCubit,
      required this.groupMetadataCubit});

  Future<String> getInitialRoute(BuildContext context) async {
    final String? idToken = await secureStorageService.getIdToken();

    if (idToken != null && idToken.isNotEmpty) {
      // Start web socket
      String? accessToken =
          await Provider.of<AuthorizationService>(context, listen: false)
              .getValidAccessToken();
      if (accessToken == null) {
        return Future.value('/signin');
      }
      msgExchangeStream.start('ws://localhost:8884/v1/ws', accessToken);

      // Handle refresh token update
      notifyFCMToken(fcmTokenCubit, accessToken);

      //setting user active
      final userid =
          await Provider.of<AuthorizationService>(context, listen: false)
              .getUserId();
      Provider.of<ActiveStatusMap>(context, listen: false).add(userid);
      Provider.of<ActiveStatusMap>(context, listen: false).update(userid, true);
      // This must be before fetch is called
      Provider.of<ChatMetaCubit>(context, listen: false).setUser(userid);
      // Backend hanldes user new case :)
      // visit route `getUserDetails`
      print(parseIdToken(idToken));
      print(parseIdToken(idToken)["name"]);
      await fetchUserDetails(
          accessToken, parseIdToken(idToken)["name"], context);
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
          RepositoryProvider<AppDb>.value(value: db),
          Provider<MessageExchangeStream>.value(value: msgExchangeStream),
          BlocProvider<FcmTokenCubit>.value(value: fcmTokenCubit),
          BlocProvider<ChatMetaCubit>.value(value: chatMetaCubit),
          ChangeNotifierProvider<DMsList>(create: (_) => DMsList()),
          ChangeNotifierProvider<GroupsList>(
            create: (_) => GroupsList(),
          ),
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
                  return CircularProgressIndicator();
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
  _MaterialAppWrapperState createState() => _MaterialAppWrapperState();
}

class _MaterialAppWrapperState extends State<MaterialAppWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    // Handle refresh token update

    super.initState();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.activityNotify.start();
    } else {
      widget.activityNotify.stop();
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
