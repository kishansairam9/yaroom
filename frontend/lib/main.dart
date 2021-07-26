import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaroom/blocs/rooms.dart';
import 'utils/router.dart';
import 'moor/db.dart';
import 'fakegen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'utils/types.dart';
import 'utils/messageExchange.dart';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

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

  for (var i = 0; i < 15; i++) {
    String rid = getRoomId();
    db.createRoom(
        roomId: rid,
        name: getCompanyName(),
        description: getAbout(),
        roomIcon: getGroupImage());
    int roomSize = getRandomInt(5, 20);
    var roomMembers = new List.generate(
        roomSize, (_) => others[Random().nextInt(others.length)]);
    roomMembers.add(userId);
    roomMembers = roomMembers.toSet().toList();
    roomSize = roomMembers.length;
    for (var j = 0; j < roomSize; j++) {
      db.addUserToRoom(roomsId: rid, userId: roomMembers[j]);
    }
    int randomNo = Random().nextInt(10) + 1;
    for (var j = 0; j < randomNo; j++) {
      db.addChannelsToRoom(
          roomId: rid,
          channelId: j.toString(),
          channelName: getRandomString(5));
      var exchange = getExchange();
      for (var k = 0; k < exchange[0].length; k++) {
        db.insertRoomsChannelMessage(
            msgId: getMsgId(),
            roomId: rid,
            channelId: j.toString(),
            fromUser: roomMembers[Random().nextInt(roomMembers.length)],
            time: DateTime.fromMicrosecondsSinceEpoch(j * 1000 * 62),
            content: exchange[0][k]);
      }
    }
  }
}

Future<void> updateDb(AppDb db, Map<dynamic, dynamic> data) async {
  data['time'] = DateTime.parse(data['time']).toLocal();
  if (data['type'] == 'ChatMessage') {
    await db
        .insertMessage(
      msgId: data['msgId'],
      toUser: data['toUser'],
      fromUser: data['fromUser'],
      time: data['time'],
      content: !data.containsKey('content') || data['content'] == ''
          ? null
          : data['content'],
      media: !data.containsKey('media') || data['media'] == ''
          ? null
          : data['media'],
      replyTo: !data.containsKey('replyTo') || data['replyTo'] == ''
          ? null
          : data['replyTo'],
    )
        .catchError((e) {
      print("Database insert failed with error $e");
    });
  } else if (data['type'] == 'RoomsMessage') {
    await db
        .insertRoomsChannelMessage(
      msgId: data['msgId'],
      roomId: data['roomId'],
      channelId: data['channelId'],
      fromUser: data['fromUser'],
      time: data['time'],
      content: data['content'] == '' ? null : data['content'],
      media: data['media'] == '' ? null : data['media'],
      replyTo: data['replyTo'] == '' ? null : data['replyTo'],
    )
        .catchError((e) {
      print("Database insert failed with error $e");
    });
  }
}

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
  String? token = await FirebaseMessaging.instance.getToken(
      vapidKey:
          'BAk6SShjzB8D0LkNQQzCtxwCVQnIBLVx1Eedl-WpcSi1bNTPGTPfzp-YLaL-ob9Md1mv7qgy0F71mdg2mVZRIV8');
  print("FCM TOKEN: ----- $token");
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    token = newToken;
    print("FCM TOKEN: ----- $token");
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
  // Fake app user
  // LATER MOVE THIS TO HYDRATED BLOC FOR PERSISTENT STORAGE
  String userId = "0";
  if (removeExistingDB) {
    fakeInsert(db, userId);
  }
  runApp(MyApp(db, userId));
}

class MyApp extends StatelessWidget {
  final _contentRouter = ContentRouter();
  late final AppDb db;
  late final String userId;

  MyApp(AppDb database, String uid) {
    db = database;
    userId = uid;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          BlocProvider<RoomsCubit>(create: (_) => RoomsCubit()),
          Provider<UserId>(
            create: (_) => userId,
          ),
          RepositoryProvider<AppDb>.value(value: db),
          Provider<MessageExchangeStream>(
            create: (_) {
              var ws = MessageExchangeStream("ws://localhost:8884");
              ws.stream.listen((encodedData) async {
                var data = jsonDecode(encodedData) as Map;
                if (data.containsKey('error')) {
                  print("WS stream returned error ${data['error']}");
                  return;
                }
                await updateDb(db, data);
              }, onError: (e) {
                print("WS stream returned error $e");
              });
              FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
                print(msg.data);
                ws.addStreamMessage(msg.data);
              });
              return ws;
            },
            lazy: false,
          )
        ],
        child: Container(
          child: MaterialApp(
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
          ),
        ));
  }
}
