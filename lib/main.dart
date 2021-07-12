import 'package:flutter/material.dart';
import 'utils/router.dart';
import 'moor/db.dart';
import 'fakegen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'utils/types.dart';

void fakeInsert(db, userId) {
  var others = [];
  // Generate fake data
  for (var i = 0; i < 30; i++) {
    int uid = getUserId();
    others.add(uid);
    db.addUser(
        userId: uid,
        name: getName(),
        about: getAbout(),
        profileImg: getImage());
    var exchange = getExchange();
    for (var j = 0; j < exchange[0].length; j++) {
      late int fromId, toId;
      if (exchange[1][j] == 0) {
        fromId = userId;
        toId = uid;
      } else {
        fromId = uid;
        toId = userId;
      }
      db.insertTextMessage(
          msgId: getMsgId(),
          fromUser: fromId,
          toUser: toId,
          time: DateTime.fromMillisecondsSinceEpoch(j * 1000 * 62),
          content: exchange[0][j]);
    }
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final removeExistingDB = true;
  AppDb db = constructDb(logStatements: true, removeExisting: removeExistingDB);
  // Fake app user
  // LATER MOVE THIS TO HYDRATED BLOC FOR PERSISTENT STORAGE
  int userId = 0;
  if (removeExistingDB) {
    fakeInsert(db, userId);
  }
  runApp(MyApp(db, userId));
}

class MyApp extends StatelessWidget {
  final _contentRouter = ContentRouter();
  late final AppDb db;
  late final int userId;

  MyApp(AppDb database, int uid) {
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
          Provider<WebSocketChannel>(
            create: (_) => WebSocketChannel.connect(
              Uri.parse('wss://echo.websocket.org'),
            ),
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
          themeMode: ThemeMode.system,
          onGenerateRoute: _contentRouter.onGenerateRoute,
        ));
  }
}
