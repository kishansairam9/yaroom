import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaroom/blocs/activeStatus.dart';
import 'package:yaroom/blocs/fcmToken.dart';
import 'package:yaroom/blocs/rooms.dart';
import 'utils/router.dart';
import 'moor/db.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'utils/types.dart';
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
import 'screens/messaging/groupsView.dart';
import 'utils/fetchBackendData.dart';
import 'package:connectivity/connectivity.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  AppDb db = constructDb(logStatements: true, removeExisting: false);
  Map<String, dynamic> data = message.data;
  await updateDb(db, data);
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

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationDocumentsDirectory(),
  );

  final removeExistingDB = true;
  AppDb db = constructDb(logStatements: true, removeExisting: removeExistingDB);

  var activeStatus = ActiveStatusMap(statusMap: Map());
  var msgStream = MessageExchangeStream();
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
    }
    await updateDb(db, data);
  }, onError: (e) {
    print("WS stream returned error $e");
  });
  FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
    print(msg.data);
    msgStream.addStreamMessage(msg.data);
  });

  const FlutterSecureStorage secureStorage = FlutterSecureStorage();
  final SecureStorageService secureStorageService =
      SecureStorageService(secureStorage);

  // Shouldn't have it, data coming from backend
  // if (removeExistingDB) {
  // fakeInsert(db, "5baa6f0d-0705-4740-b4a1-ae1b44bbd10b"); // abhi
  // fakeInsert(db, "aa616733-4e1b-4899-950f-48ea990d8db2"); // kalyan
  // fakeInsert(db, "ef8a936c-888f-4863-8d30-8a62c7c20c29"); // kishan
  // }

  runApp(
      MyApp(db, msgStream, secureStorageService, fcmTokenCubit, activeStatus));
}

class ConnectivityCheck extends StatelessWidget {
  final Widget child;

  ConnectivityCheck({required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
        stream: Connectivity().onConnectivityChanged,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == ConnectivityResult.none) {
            return Container(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Image(
                        image:
                            AssetImage('assets/yaroom_full_logo_200x200.png')),
                    Container(
                      child:
                          Text('No network!', textDirection: TextDirection.ltr),
                    )
                  ],
                ),
              ),
            );
          } else {
            return child;
          }
        });
  }
}

class MyApp extends StatelessWidget {
  late final AppDb db;
  late final MessageExchangeStream msgExchangeStream;
  late final SecureStorageService secureStorageService;
  late final FcmTokenCubit fcmTokenCubit;
  late final ActiveStatusMap activeStatus;

  MyApp(
      AppDb db,
      MessageExchangeStream msgExchangeStream,
      SecureStorageService secureStorageService,
      FcmTokenCubit fcmTokenCubit,
      ActiveStatusMap activeStatus) {
    this.db = db;
    this.secureStorageService = secureStorageService;
    this.msgExchangeStream = msgExchangeStream;
    this.fcmTokenCubit = fcmTokenCubit;
    this.activeStatus = activeStatus;
  }

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

      // Backend hanldes user new case :)
      // visit route `getUserDetails`
      await fetchUserDetails(accessToken, context);
      print(accessToken);
      // visit route `getLaterMessages`
      await fetchLaterMessages(accessToken, null, context);

      return Future.value('/');
    }
    return Future.value('/signin');
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityCheck(
        child: MultiProvider(
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
        // BlocProvider(create: create)
        RepositoryProvider<AppDb>.value(value: db),
        Provider<MessageExchangeStream>.value(value: msgExchangeStream),
        BlocProvider<FcmTokenCubit>.value(value: fcmTokenCubit),
        ChangeNotifierProvider<GroupChatData>(
          create: (_) => GroupChatData(),
        ),
        BlocProvider(create: (context) {
          return FilePickerCubit(
              initialState: FilePickerDetails(media: Map(), filesAttached: 0));
        })
      ],
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

Future<bool> delMsg(BuildContext context, User user) async {
  var oldMsg = await RepositoryProvider.of<AppDb>(context)
      .getUserMsgsToDelete(userId: user.userId, count: 10)
      .get();
  for (int i = 0; i < oldMsg.length; i++) {
    await RepositoryProvider.of<AppDb>(context)
        .deleteMsg(msgId: oldMsg[i].msgId);
  }
  return Future.value(true);
}

Future<bool> delOldMsg(BuildContext context, User user) async {
  print('hola');
  var oldMsgCount = await RepositoryProvider.of<AppDb>(context)
      .getUserMsgCount(userId: user.userId)
      .get();
  if (oldMsgCount[0] > 10) {
    delMsg(context, user);
  }
  return Future.value(true);
}

Future<bool> cleanFrontendDB(BuildContext context) async {
  final userid = await Provider.of<AuthorizationService>(context, listen: false)
      .getUserId();
  var oldUsers = await RepositoryProvider.of<AppDb>(context)
      .getAllOtherUsers(userId: userid)
      .get();
  for (int i = 0; i < oldUsers.length; i++) {
    await delOldMsg(context, oldUsers[i]);
  }
  print("hi");
  return Future.value(true);
}
