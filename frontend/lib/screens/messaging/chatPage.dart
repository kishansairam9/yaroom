import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yaroom/utils/authorizationService.dart';
import '../components/searchDelegate.dart';
import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaroom/screens/components/msgBox.dart';
import 'package:yaroom/utils/authorizationService.dart';
import '../components/contactView.dart';
import 'package:provider/provider.dart';
import '../../utils/messageExchange.dart';
import '../../utils/types.dart';
import '../../blocs/chats.dart';
import '../../blocs/chatMeta.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  late final String userId, name;
  late final String? image;

  ChatPage(ChatPageArguments args) {
    this.userId = args.userId;
    this.name = args.name;
  }
  ChatPageState createState() => new ChatPageState();
}

class ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  late final webSocketSubscription;
  List<ChatMessage> newmsgs = [];
  bool moreload = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    // Clean up the controller & subscription when the widget is disposed.
    webSocketSubscription.cancel();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state.toString());
    switch (state) {
      case AppLifecycleState.resumed:
        Navigator.of(context).pushNamedAndRemoveUntil(
            '/chat', (Route<dynamic> route) => route.isFirst,
            arguments:
                ChatPageArguments(name: widget.name, userId: widget.userId));
        break;
      default:
        break;
    }
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }

  void savefile(data) async {
    final directory = await getTemporaryDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    print(directory.path + '/' + data['name']);
    var file = await File(directory.path + '/' + data['name'])
        .writeAsBytes(Uint8List.fromList(data['bytes'].cast<int>()));

    await saveFileToMediaStore(file, data['name']);
    await file.delete();
  }

  Future<Widget> _buildSingleMessage(
      BuildContext context, ChatMessage msg, bool isMe) async {
    String? accessToken =
        await Provider.of<AuthorizationService>(context, listen: false)
            .getValidAccessToken();
    if (accessToken == null) {
      Navigator.pushNamed(context, '/signin');
    }
    if (msg.media == null) {
      if (msg.content == null) {
        return Container();
      } else {
        return Text(
          msg.content!, // Using unicode space is imp as flutter engine trims otherwise
          textAlign: isMe ? TextAlign.right : TextAlign.left,
          style: TextStyle(color: Colors.white),
        );
      }
    } else {
      var media = await http.get(
          Uri.parse('http://localhost:8884/v1/media/' + msg.media!),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': "Bearer $accessToken",
          });
      var data = jsonDecode(media.body) as Map;
      if (msg.content == null) {
        var temp = data['name'].split(".");
        if (['jpg', 'jpeg', 'png'].contains(temp.last)) {
          return Image.memory(Uint8List.fromList(data['bytes'].cast<int>()));
        } else {
          print('hi');
          return Row(
            children: [
              Text(data['name']),
              IconButton(
                icon: const Icon(Icons.file_download),
                tooltip: 'download',
                onPressed: () {
                  savefile(data);
                },
              ),
            ],
          );
        }
      } else {
        var temp = data['name'].split(".");
        return Column(
          children: [
            ['jpg', 'jpeg', 'png'].contains(temp.last)
                ? Image.memory(Uint8List.fromList(data['bytes'].cast<int>()))
                : Row(
                    children: [
                      Text(data['name']),
                      IconButton(
                        icon: const Icon(Icons.file_download),
                        tooltip: 'download',
                        onPressed: () {
                          savefile(data);
                        },
                      ),
                    ],
                  ),
            Text(
              msg.content!,
              textAlign: isMe ? TextAlign.right : TextAlign.left,
              style: TextStyle(color: Colors.white),
            ),
          ],
        );
      }
    }
  }

  _buildMessage(ChatMessage msg, bool prevIsSame, DateTime? prependDay) {
    final bool isMe = msg.fromUser == Provider.of<UserId>(context);
    final time = TimeOfDay.fromDateTime(msg.time.toLocal()).format(context);
    final double msgSpacing = prevIsSame ? 5 : 11;
    final double sideMargin = 60;
    final msgContent = Bubble(
      margin: isMe
          ? BubbleEdges.only(top: msgSpacing, left: sideMargin)
          : BubbleEdges.only(top: msgSpacing, right: sideMargin),
      nip: isMe ? BubbleNip.rightTop : BubbleNip.leftTop,
      showNip: !prevIsSame,
      alignment: isMe ? Alignment.topRight : Alignment.topLeft,
      color: isMe ? Colors.blueAccent : Colors.blueGrey,
      padding: BubbleEdges.all(10),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: 60),
                child: Builder(
                  builder: (context) {
                    return FutureBuilder(
                        future: _buildSingleMessage(context, msg, isMe),
                        builder: (BuildContext context,
                            AsyncSnapshot<Widget> snapshot) {
                          if (snapshot.hasData) {
                            return snapshot.data!;
                          }
                          return CircularProgressIndicator();
                        });
                  },
                )),
          ),
          Positioned(
              bottom: 0,
              right: 0,
              child: Text(time,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: Colors.grey)))
        ],
      ),
    );
    if (prependDay == null) {
      return msgContent;
    }
    late final dateString;
    if (DateTime.now().day == prependDay.day) {
      dateString = "Today";
    } else if (DateTime.now().difference(prependDay).inDays == -1) {
      dateString = "Yesterday";
    } else {
      dateString =
          "${prependDay.day.toString().padLeft(2, "0")}/${prependDay.month.toString().padLeft(2, "0")}/${prependDay.year.toString().substring(2)}";
    }
    return Column(
      children: [
        Bubble(
          margin: BubbleEdges.only(top: msgSpacing),
          alignment: Alignment.center,
          color: Colors.amber[200],
          child: Text(dateString,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: Theme.of(context).textTheme.subtitle2!.fontSize)),
        ),
        msgContent
      ],
    );
  }

  // To display profile
  _showContact(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext c) {
          return ViewContact(User(
            userId: widget.userId,
            name: widget.name,
          ));
        });
  }

  loadMore(List<ChatMessage> msgs) async {
    if (msgs.isNotEmpty && moreload) {
      String? accessToken =
          await Provider.of<AuthorizationService>(context, listen: false)
              .getValidAccessToken();
      if (accessToken == null) {
        Navigator.pushNamed(context, '/signin');
      }
      var req = await http.get(
          Uri.parse(
              'http://localhost:8884/v1/getOlderMessages?msgType=ChatMessage&lastMsgId=' +
                  msgs[0].msgId +
                  '&exchangeId=' +
                  getExchangeId() +
                  '&limit=15'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': "Bearer $accessToken",
          });
      if (req.body != "null") {
        if (req.body.contains(new RegExp("{\"error\"", caseSensitive: false))) {
          return;
        }
        print(req.body);
        var results = jsonDecode(req.body).cast<Map<String, dynamic>>();
        List<ChatMessage> temp = [];
        for (int i = 0; i < results.length; i++) {
          ChatMessage msg = ChatMessage(
            fromUser: results[i]['fromUser'],
            msgId: results[i]['msgId'],
            toUser: results[i]['toUser'],
            time: DateTime.parse(results[i]['time']),
            content: results[i]['content'],
            // media: results[i]['media']
          );
          temp.add(msg);
        }
        temp.sort((a, b) => a.msgId.compareTo(b.msgId));
        setState(() {
          newmsgs = temp;
        });
      } else {
        setState(() {
          moreload = false;
        });
      }
    }
  }

  Widget _buildMessagesView(List<ChatMessage> msgs) {
    if (msgs.length < 15 && moreload) {
      loadMore(msgs);
      msgs.insertAll(0, newmsgs);
    }
    return Expanded(
      child: Column(
        children: [
          Expanded(
              child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                  scrollInfo.metrics.maxScrollExtent) {
                loadMore(msgs);
                // newmsgs.addAll(msgs);
                msgs.insertAll(0, newmsgs);
                // setState(() {
                //   newmsgs:[];
                // });
                return true;
              }
              return false;
            },
            child: ListView.builder(
                reverse: true,
                padding: EdgeInsets.only(bottom: 15.0),
                itemCount: msgs.length,
                itemBuilder: (BuildContext context, int index) {
                  final bool prevIsSame = msgs.length - 2 - index >= 0
                      ? (msgs[msgs.length - 2 - index].fromUser ==
                          msgs[msgs.length - 1 - index].fromUser)
                      : false;
                  final bool prependDayCond = msgs.length - 2 - index >= 0
                      ? (msgs[msgs.length - 2 - index].time.day !=
                          msgs[msgs.length - 1 - index].time.day)
                      : true;
                  DateTime? prependDay = prependDayCond
                      ? msgs[msgs.length - 1 - index].time
                      : null;
                  return _buildMessage(msgs[msgs.length - 1 - index],
                      prevIsSame && !prependDayCond, prependDay);
                }),
          ))
        ],
      ),
    );
  }

  void _sendMessage(
      {required BuildContext context,
      String? content,
      Map? media,
      int? replyTo}) {
    if (media != null && media.keys.length == 0) media = null;
    if (content == '') content = null;
    if (media == null && content == null) {
      return;
    }
    Provider.of<MessageExchangeStream>(context, listen: false)
        .sendWSMessage(jsonEncode({
      'type': 'ChatMessage',
      'toUser': widget.userId,
      'fromUser': Provider.of<UserId>(context, listen: false),
      'content': content,
      'time': DateTime.now().toUtc().toIso8601String(),
      'mediaData': media,
      'replyTo': replyTo,
    }));
    BlocProvider.of<FilePickerCubit>(context, listen: false)
        .updateFilePicker(media: Map(), filesAttached: 0);
  }

  Future<bool> onBackPress() {
    Navigator.of(context).pop();
    return Future.value(false);
  }

  String getExchangeId() {
    var ids = <String>[
      Provider.of<UserId>(context, listen: false),
      widget.userId
    ];
    ids.sort();
    return ids[0] + ":" + ids[1];
  }

  Widget build(BuildContext context) {
    return FutureBuilder(
        future: RepositoryProvider.of<AppDb>(context)
            .getUserChat(otherUser: widget.userId)
            .get(),
        builder:
            (BuildContext context, AsyncSnapshot<List<ChatMessage>> snapshot) {
          if (snapshot.hasData) {
            return BlocProvider(create: (context) {
              var cubit = UserChatCubit(
                  otherUser: widget.userId, initialState: snapshot.data!);
              webSocketSubscription =
                  Provider.of<MessageExchangeStream>(context, listen: false)
                      .stream
                      .where((encodedData) {
                var data = jsonDecode(encodedData);
                if (data.containsKey('error') ||
                    data.containsKey('active') ||
                    data.containsKey('update') ||
                    data.containsKey('exit')) {
                  return false;
                }
                return (data['type'] == 'ChatMessage' &&
                    (data['fromUser'] == widget.userId ||
                        data['toUser'] == widget.userId));
              }).listen((encodedData) {
                var data = jsonDecode(encodedData);
                cubit.addMessage(
                  msgId: data['msgId'],
                  toUser: data['toUser'],
                  fromUser: data['fromUser'],
                  time: DateTime.parse(data['time']).toLocal(),
                  content: data['content'] == '' ? null : data['content'],
                  media: data['media'] == '' ? null : data['media'],
                  replyTo: data['replyTo'] == '' ? null : data['replyTo'],
                );
              }, onError: (error) {
                print(error);
                return SnackBar(
                    content: Text(
                        'Error has occured while receiving from websocket'));
              });
              return cubit;
            }, child: Builder(builder: (context) {
              return Scaffold(
                  appBar: AppBar(
                    automaticallyImplyLeading: false,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    titleSpacing: 0,
                    title: ListTile(
                      onTap: () => _showContact(context),
                      contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
                      tileColor: Colors.transparent,
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[350],
                        foregroundImage: iconImageWrapper(widget.userId),
                      ),
                      title: Text(
                        widget.name,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    actions: <Widget>[
                      IconButton(
                        onPressed: () => {
                          showSearch(
                              context: context,
                              delegate: ExchangeSearchDelegate(
                                  exchangeId: getExchangeId(),
                                  msgType: "ChatMessage",
                                  limit: 100))
                        },
                        icon: Icon(Icons.search),
                        tooltip: 'Search',
                      ),
                      IconButton(
                        onPressed: () => {},
                        icon: Icon(Icons.more_vert),
                        tooltip: 'More',
                      )
                    ],
                  ),
                  body: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        BlocBuilder<UserChatCubit, List<ChatMessage>>(
                            builder: (BuildContext context,
                                    List<ChatMessage> state) =>
                                _buildMessagesView(state)),
                        MsgBox(
                            sendMessage: _sendMessage,
                            callIfEmojiClosedAndBackPress: onBackPress)
                      ]));
            }));
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return SnackBar(
                content: Text('Error has occured while reading from local DB'));
          }
          return CircularProgressIndicator();
        });
  }
}
