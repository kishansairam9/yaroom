import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaroom/blocs/fcmToken.dart';
import 'package:yaroom/blocs/rooms.dart';
import 'utils/router.dart';
import 'moor/db.dart';
import 'fakegen.dart';
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

  // TODO: Upload token to backend
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
        : await getTemporaryDirectory(),
  );

  final removeExistingDB = true;
  AppDb db = constructDb(logStatements: true, removeExisting: removeExistingDB);

  var msgStream = MessageExchangeStream();
  msgStream.stream.listen((encodedData) async {
    var data = jsonDecode(encodedData) as Map;
    if (data.containsKey('error')) {
      print("WS stream returned error ${data['error']}");
      return;
    } else if (data.containsKey('active')) {
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

  if (removeExistingDB) {
    // ef8a936c-888f-4863-8d30-8a62c7c20c29 kishan
    fakeInsert(db, "ef8a936c-888f-4863-8d30-8a62c7c20c29");
  }

  runApp(MyApp(db, msgStream, secureStorageService, fcmTokenCubit));
}

class MyApp extends StatelessWidget {
  late final AppDb db;
  late final MessageExchangeStream msgExchangeStream;
  late final SecureStorageService secureStorageService;
  late final FcmTokenCubit fcmTokenCubit;

  MyApp(AppDb db, MessageExchangeStream msgExchangeStream,
      SecureStorageService secureStorageService, FcmTokenCubit fcmTokenCubit) {
    this.db = db;
    this.secureStorageService = secureStorageService;
    this.msgExchangeStream = msgExchangeStream;
    this.fcmTokenCubit = fcmTokenCubit;
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
      return Future.value('/');
    }
    return Future.value('/signin');
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
        RepositoryProvider<AppDb>.value(value: db),
        Provider<MessageExchangeStream>.value(value: msgExchangeStream),
        BlocProvider<FcmTokenCubit>.value(value: fcmTokenCubit),
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
    );
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
