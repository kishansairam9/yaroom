import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'utils/router.dart';
import 'moor/db.dart';
import 'fakegen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'utils/types.dart';
import 'utils/websocket.dart';
import 'dart:convert';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
                data['time'] = DateTime.parse(data['time']).toLocal();
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
