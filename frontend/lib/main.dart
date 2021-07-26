import 'dart:math';

import 'package:flutter/material.dart';
import 'package:yaroom/auth.dart';
import 'utils/router.dart';
import 'moor/db.dart';
import 'fakegen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'utils/types.dart';
import 'utils/websocket.dart';
import 'dart:convert';
import 'auth.dart';
import 'login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'utils/secureStorageService.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'utils/authorizationService.dart';

void fakeInsert(AppDb db, UserId userId) {
  var others = [];
  // Generate fake data
  db.addUser(
      userId: userId,
      name: getName(),
      about: getAbout(),
      profileImg: getImage());
  for (var i = 0; i < 30; i++) {
    String uid = getUserId();
    others.add(uid);
    db.addUser(
        userId: uid,
        name: getName(),
        about: getAbout(),
        profileImg: getImage());
    var exchange = getExchange();
    for (var j = 0; j < exchange[0].length; j++) {
      late String fromId, toId;
      if (exchange[1][j] == 0) {
        fromId = userId;
        toId = uid;
      } else {
        fromId = uid;
        toId = userId;
      }
      db.insertMessage(
          msgId: getMsgId(),
          fromUser: fromId,
          toUser: toId,
          time: DateTime.fromMillisecondsSinceEpoch(j * 1000 * 62),
          content: exchange[0][j]);
    }
  }
  for (var i = 0; i < 30; i++) {
    String gid = getGroupId();
    db.createGroup(
        groupId: gid,
        name: getCompanyName(),
        description: getAbout(),
        groupIcon: getGroupImage());
    int groupSize = getRandomInt(5, 20);
    var groupMembers = new List.generate(
        groupSize, (_) => others[Random().nextInt(others.length)]);
    groupMembers.add(userId);
    groupMembers = groupMembers.toSet().toList();
    groupSize = groupMembers.length;
    for (var j = 0; j < groupSize; j++) {
      db.addUserToGroup(groupId: gid, userId: groupMembers[j]);
    }
    var exchange = getExchange();
    for (var j = 0; j < exchange[0].length; j++) {
      db.insertGroupChatMessage(
          msgId: getMsgId(),
          groupId: gid,
          fromUser: groupMembers[Random().nextInt(groupMembers.length)],
          time: DateTime.fromMillisecondsSinceEpoch(j * 1000 * 62),
          content: exchange[0][j]);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final removeExistingDB = true;
  AppDb db = constructDb(logStatements: true, removeExisting: removeExistingDB);
  // Fake app user
  // LATER MOVE THIS TO HYDRATED BLOC FOR PERSISTENT STORAGE
  String userId = "0";
  const FlutterSecureStorage secureStorage = FlutterSecureStorage();
  final SecureStorageService secureStorageService =
      SecureStorageService(secureStorage);
  final String? refreshToken = await secureStorageService.getRefreshToken();
  final String? idToken = await secureStorageService.getIdToken();
  bool loggedIn = !(refreshToken == null);
  if (idToken != null && idToken.isNotEmpty) {
    loggedIn = true;
    userId = parseIdToken(idToken)['https://yaroom.com/userId'];
  }
  if (removeExistingDB) {
    fakeInsert(db, userId);
  }
  runApp(MultiProvider(
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
    ],
    child: MyApp(db, userId, loggedIn),
  ));
  // runApp(MyApp(db, userId, loggedIn));
}

class MyApp extends StatelessWidget {
  final _contentRouter = ContentRouter();
  late final AppDb db;
  late final String userId;
  late final bool loggedIn;

  MyApp(AppDb database, String uid, bool loginStatus) {
    db = database;
    userId = uid;
    loggedIn = loginStatus;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          Provider<UserId>(
            create: (_) => userId,
          ),
          RepositoryProvider<AppDb>.value(value: db),
          Provider<WebSocketWrapper>(
            create: (_) {
              var ws = WebSocketWrapper("ws://localhost:8884");
              ws.stream.listen((encodedData) async {
                var data = jsonDecode(encodedData) as Map;
                if (data.containsKey('error')) {
                  print("WS stream returned error ${data['error']}");
                  return;
                }
                data['time'] = DateTime.parse(data['time']);
                if (data['type'] == 'ChatMessage') {
                  await db
                      .insertMessage(
                    msgId: data['msgId'],
                    toUser: data['toUser'],
                    fromUser: data['fromUser'],
                    time: data['time'],
                    content:
                        !data.containsKey('content') || data['content'] == ''
                            ? null
                            : data['content'],
                    media: !data.containsKey('media') || data['media'] == ''
                        ? null
                        : data['media'],
                    replyTo:
                        !data.containsKey('replyTo') || data['replyTo'] == ''
                            ? null
                            : data['replyTo'],
                  )
                      .catchError((e) {
                    print("Database insert failed with error $e");
                  });
                } else if (data['type'] == 'GroupChatMessage') {
                  await db
                      .insertGroupChatMessage(
                    msgId: data['msgId'],
                    groupId: data['groupId'],
                    fromUser: data['fromUser'],
                    time: data['time'],
                    content:
                        !data.containsKey('content') || data['content'] == ''
                            ? null
                            : data['content'],
                    media: !data.containsKey('media') || data['media'] == ''
                        ? null
                        : data['media'],
                    replyTo:
                        !data.containsKey('replyTo') || data['replyTo'] == ''
                            ? null
                            : data['replyTo'],
                  )
                      .catchError((e) {
                    print("Database insert failed with error $e");
                  });
                }
              }, onError: (e) {
                print("WS stream returned error $e");
              });
              return ws;
            },
            lazy: false,
          )
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: loggedIn ? '/tabs' : '/signin',
          // initialRoute: '/signin',
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
        ));
  }
}
