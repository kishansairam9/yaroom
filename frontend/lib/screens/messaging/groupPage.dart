import 'dart:typed_data';
import 'package:yaroom/blocs/friendRequestsData.dart';
import 'package:yaroom/utils/authorizationService.dart';
import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaroom/screens/components/msgBox.dart';
import 'package:yaroom/utils/backendRequests.dart';
import '../components/contactView.dart';
import '../components/searchDelegate.dart';
import 'package:provider/provider.dart';
import '../../utils/messageExchange.dart';
import '../../utils/types.dart';
import '../../blocs/groupChats.dart';
import 'package:http/http.dart' as http;
import '../../blocs/groupMetadata.dart';
import '../../blocs/activeStatus.dart';
import '../../blocs/chatMeta.dart';

class GroupChatPage extends StatefulWidget {
  late final String groupId;

  GroupChatPage(GroupChatPageArguments args) {
    this.groupId = args.groupId;
  }
  GroupChatPageState createState() => new GroupChatPageState();
}

class GroupChatPageState extends State<GroupChatPage> {
  final inputController = TextEditingController();
  late final webSocketSubscription;
  List<GroupChatMessage> newmsgs = [];
  bool moreload = true;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller & subscription when the widget is disposed.
    webSocketSubscription.cancel();
    inputController.dispose();
    super.dispose();
  }

  // handling backPress when emoji keyboard is implemented
  Future<bool> onBackPress() {
    Navigator.of(context).pop();
    return Future.value(false);
  }

  Future<Widget> buildSingleMsg(
      BuildContext context, GroupChatMessage msg) async {
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
        return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              msg.content!,
              textAlign: TextAlign.left,
              style: TextStyle(color: Colors.white),
            ));
      }
    } else {
      var media = await http.get(
          Uri.parse('$BACKEND_URL/v1/media/' + msg.media!),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': "Bearer $accessToken",
          });
      var data = jsonDecode(media.body) as Map;
      if (msg.content == null) {
        var temp = data['name'].split(".");
        return Align(
            alignment: Alignment.centerLeft,
            child: ['jpg', 'jpeg', 'png'].contains(temp.last)
                ? Image.memory(Uint8List.fromList(data['bytes'].cast<int>()))
                : Row(
                    children: [
                      Text(data['name']),
                      IconButton(
                        icon: const Icon(Icons.file_download),
                        tooltip: 'download',
                        onPressed: () {
                          savefile(data, context);
                        },
                      ),
                    ],
                  ));
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
                          savefile(data, context);
                        },
                      ),
                    ],
                  ),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  msg.content!,
                  textAlign: TextAlign.left,
                  style: TextStyle(color: Colors.white),
                )),
          ],
        );
      }
    }
  }

  _buildMessage(BuildContext context, GroupChatMessage msg, bool prevIsSame,
      DateTime? prependDay) {
    var query = Provider.of<GroupMetadataCubit>(context, listen: false)
        .state
        .data[widget.groupId]!
        .groupMembers
        .where((element) => element.userId == msg.fromUser)
        .toList();
    var curUser = User(name: 'UnknownUser', userId: msg.fromUser);
    if (!query.isEmpty) {
      curUser = query[0];
    }
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
      child: Row(
        children: [
          Flexible(
              flex: 10,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            curUser.name,
                            style: TextStyle(
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .subtitle1!
                                    .fontSize,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Builder(
                          builder: (context) {
                            return FutureBuilder(
                                future: buildSingleMsg(context, msg),
                                builder: (BuildContext context,
                                    AsyncSnapshot<Widget> snapshot) {
                                  if (snapshot.hasData) {
                                    return snapshot.data!;
                                  }
                                  return LoadingBar;
                                });
                          },
                        ),
                        Align(
                            alignment: Alignment.bottomRight,
                            child: Text(time,
                                textAlign: TextAlign.end,
                                style: TextStyle(color: Colors.grey)))
                      ]))),
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
        Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: Theme.of(context).textTheme.subtitle1!.fontSize! / 2 +
                      msgSpacing,
                ),
                Divider(),
              ],
            ),
            Bubble(
              margin: BubbleEdges.only(top: msgSpacing),
              alignment: Alignment.center,
              color: Colors.transparent,
              elevation: 0,
              child: Text(dateString,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey[350],
                      fontSize:
                          Theme.of(context).textTheme.subtitle1!.fontSize)),
            ),
          ],
        ),
        msgContent
      ],
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldkey = new GlobalKey();
  loadMore(List<GroupChatMessage> msgs) async {
    if (msgs.isNotEmpty && moreload) {
      String? accessToken =
          await Provider.of<AuthorizationService>(context, listen: false)
              .getValidAccessToken();
      if (accessToken == null) {
        Navigator.pushNamed(context, '/signin');
      }
      var req = await http.get(
          Uri.parse(
              '$BACKEND_URL/v1/getOlderMessages?msgType=GroupMessage&lastMsgId=' +
                  msgs[0].msgId +
                  '&exchangeId=' +
                  widget.groupId +
                  '&limit=15'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': "Bearer $accessToken",
          });
      if (req.body != "null" && req.body != "") {
        if (req.body.contains(new RegExp("{\"error\"", caseSensitive: false))) {
          return;
        }
        print(req.body);
        var results = jsonDecode(req.body).cast<Map<String, dynamic>>();
        List<GroupChatMessage> temp = [];
        for (int i = 0; i < results.length; i++) {
          GroupChatMessage msg = GroupChatMessage(
              fromUser: results[i]['fromUser'],
              msgId: results[i]['msgId'],
              groupId: results[i]['groupId'],
              time: DateTime.parse(results[i]['time']),
              content: results[i]['content'],
              media: results[i]['media']);
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

  Widget _buildMessagesView(List<GroupChatMessage> msgs) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
              child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                  scrollInfo.metrics.maxScrollExtent) {
                loadMore(msgs);
                msgs.insertAll(0, newmsgs);
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
                  return _buildMessage(context, msgs[msgs.length - 1 - index],
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
      'type': 'GroupMessage',
      'groupId': widget.groupId,
      'fromUser': Provider.of<UserId>(context, listen: false),
      'content': content,
      'time': DateTime.now().toUtc().toIso8601String(),
      'mediaData': media,
      'replyTo': replyTo,
    }));
    BlocProvider.of<FilePickerCubit>(context, listen: false)
        .updateFilePicker(media: Map(), filesAttached: 0);
  }

  DrawerHeader _getDrawerHeader(members) {
    return DrawerHeader(
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[350],
          foregroundImage: iconImageWrapper(widget.groupId),
        ),
        tileColor: Colors.transparent,
        title: BlocBuilder<GroupMetadataCubit, GroupMetadataMap>(
          builder: (context, state) {
            return Text(
              state.data[widget.groupId]!.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 20),
            );
          },
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              IconButton(
                  onPressed: () => {
                        Navigator.pushNamed(context, '/editgroup',
                            arguments: {"groupId": widget.groupId})
                      },
                  tooltip: "Settings",
                  icon: Icon(Icons.settings)),
              Text("Settings")
            ],
          ),
          Column(
            children: [
              IconButton(
                  onPressed: () => {
                        showSearch(
                            context: context,
                            delegate: ExchangeSearchDelegate(
                                exchangeId: widget.groupId,
                                msgType: "GroupMessage",
                                limit: 100))
                      },
                  tooltip: "Search",
                  icon: Icon(Icons.search)),
              Text("Search")
            ],
          ),
          Column(
            children: [
              IconButton(
                  onPressed: () => {
                        showDialog(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                  title: Text("Exit Group"),
                                  content: Text(
                                      "Are you sure you want to exit the group? The related chat will no longer be displayed to you."),
                                  actions: [
                                    TextButton(
                                        onPressed: () async {
                                          // request to backend to remove user from group
                                          await exitGroup(
                                              widget.groupId, context);
                                          await Navigator.pushReplacementNamed(
                                              context, '/',
                                              arguments:
                                                  HomePageArguments(index: 2));
                                        },
                                        child: Text("Yes")),
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("No"))
                                  ]);
                            })
                      },
                  tooltip: "Exit",
                  icon: Icon(Icons.exit_to_app)),
              Text("Exit")
            ],
          ),
        ],
      ),
    ]));
  }

  Widget build(BuildContext context) {
    return BlocBuilder<GroupMetadataCubit, GroupMetadataMap>(
        bloc: Provider.of<GroupMetadataCubit>(context, listen: false),
        builder: (BuildContext _, state) {
          if (state.data[widget.groupId] != null) {
            List<User> groupMembers = state.data[widget.groupId]!.groupMembers;
            return FutureBuilder(
                future: RepositoryProvider.of<AppDb>(context)
                    .getGroupChat(groupId: widget.groupId)
                    .get(),
                builder: (BuildContext _,
                    AsyncSnapshot<List<GroupChatMessage>> groupChatSnapshot) {
                  if (groupChatSnapshot.hasData) {
                    return MultiProvider(
                      providers: [
                        Provider<List<User>>(create: (_) => groupMembers),
                        BlocProvider(create: (context) {
                          var cubit = GroupChatCubit(
                              groupId: widget.groupId,
                              initialState: groupChatSnapshot.data!);
                          webSocketSubscription =
                              Provider.of<MessageExchangeStream>(context,
                                      listen: false)
                                  .stream
                                  .where((encodedData) {
                            if (encodedData == "" ||
                                encodedData == "null" ||
                                encodedData == "true" ||
                                encodedData == "false") return false;
                            var data = jsonDecode(encodedData);
                            if (data.containsKey('error') ||
                                data.containsKey('active') ||
                                data.containsKey('update') ||
                                data.containsKey('friendRequest') ||
                                data.containsKey('exit')) {
                              return false;
                            }
                            return data['type'] == 'GroupMessage' &&
                                data['groupId'] == widget.groupId;
                          }).listen((encodedData) {
                            var data = jsonDecode(encodedData);
                            Future.delayed(Duration(milliseconds: 500), () {
                              Provider.of<ChatMetaCubit>(context, listen: false)
                                  .read(
                                      data['groupId'], data['msgId'], context);
                            });
                            cubit.addMessage(
                              msgId: data['msgId'],
                              groupId: data['groupId'],
                              fromUser: data['fromUser'],
                              time: DateTime.parse(data['time']),
                              content: data['content'] == ''
                                  ? null
                                  : data['content'],
                              media: data['media'] == '' ? null : data['media'],
                              replyTo: data['replyTo'] == ''
                                  ? null
                                  : data['replyTo'],
                            );
                          }, onError: (error) {
                            print(error);
                            return SnackBar(
                                content: Text(
                                    'Error has occured while receiving from websocket'));
                          });
                          return cubit;
                        })
                      ],
                      child: Builder(builder: (context) {
                        String uid =
                            Provider.of<UserId>(context, listen: false);
                        return Scaffold(
                            key: _scaffoldkey,
                            endDrawer: Drawer(
                                child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                _getDrawerHeader(
                                    groupMembers.map((User e) => e.userId)),
                                ...groupMembers.map((User e) =>
                                    BlocBuilder<ActiveStatusCubit, bool>(
                                      bloc:
                                          Provider.of<ActiveStatusMap>(context)
                                              .get(e.userId),
                                      builder: (context, state) {
                                        return ListTile(
                                            onTap: () => showModalBottomSheet(
                                                context: context,
                                                builder: (BuildContext c) {
                                                  return BlocBuilder<
                                                          FriendRequestCubit,
                                                          FriendRequestDataMap>(
                                                      bloc: Provider.of<
                                                              FriendRequestCubit>(
                                                          context,
                                                          listen: false),
                                                      builder:
                                                          (context, state) {
                                                        if (state.data
                                                            .containsKey(
                                                                e.userId)) {
                                                          return ViewContact(
                                                              state.data[
                                                                  e.userId]!,
                                                              uid);
                                                        } else {
                                                          return ViewContact(
                                                              FriendRequestData(
                                                                  userId:
                                                                      e.userId,
                                                                  name: e.name,
                                                                  about: e.about ==
                                                                          null
                                                                      ? ""
                                                                      : e.about!,
                                                                  status: -1),
                                                              uid);
                                                        }
                                                      });
                                                }),
                                            tileColor: Colors.transparent,
                                            leading: Stack(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor:
                                                      Colors.grey[350],
                                                  foregroundImage:
                                                      iconImageWrapper(
                                                          e.userId),
                                                ),
                                                Positioned(
                                                    bottom: 0,
                                                    right: 0,
                                                    child: Container(
                                                        width: 15,
                                                        height: 15,
                                                        decoration:
                                                            new BoxDecoration(
                                                          color: state
                                                              ? Colors.green
                                                              : Colors.grey,
                                                          shape:
                                                              BoxShape.circle,
                                                        )))
                                              ],
                                            ),
                                            title: Text(
                                              e.name,
                                            ));
                                      },
                                    ))
                              ],
                            )),
                            appBar: AppBar(
                              leading: Builder(
                                  builder: (context) => IconButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      icon: Icon(Icons.arrow_back))),
                              titleSpacing: 0,
                              title: Builder(
                                  builder: (context) => ListTile(
                                      onTap: () =>
                                          Scaffold.of(context).openEndDrawer(),
                                      contentPadding: EdgeInsets.only(
                                          left: 0.0, right: 0.0),
                                      tileColor: Colors.transparent,
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.grey[350],
                                        foregroundImage:
                                            iconImageWrapper(widget.groupId),
                                      ),
                                      title: BlocBuilder<GroupMetadataCubit,
                                              GroupMetadataMap>(
                                          bloc: Provider.of<GroupMetadataCubit>(
                                              context,
                                              listen: false),
                                          builder: (context, state) {
                                            return Text(
                                              state.data[widget.groupId]!.name,
                                              style: TextStyle(
                                                  color: Colors.white),
                                            );
                                          }))),
                              actions: <Widget>[
                                IconButton(
                                  onPressed: () => {
                                    showSearch(
                                        context: context,
                                        delegate: ExchangeSearchDelegate(
                                            exchangeId: widget.groupId,
                                            msgType: "GroupMessage",
                                            limit: 100))
                                  },
                                  icon: Icon(Icons.search),
                                  tooltip: 'Search',
                                ),
                                IconButton(
                                  onPressed: () => {
                                    _scaffoldkey.currentState!.openEndDrawer()
                                  },
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
                                  BlocBuilder<GroupChatCubit,
                                          List<GroupChatMessage>>(
                                      builder: (BuildContext context,
                                              List<GroupChatMessage> state) =>
                                          _buildMessagesView(state)),
                                  MsgBox(
                                    sendMessage: _sendMessage,
                                    callIfEmojiClosedAndBackPress: onBackPress,
                                  )
                                ]));
                      }),
                    );
                  } else if (groupChatSnapshot.hasError) {
                    print(groupChatSnapshot.error);
                    return SnackBar(
                        content: Text(
                            'Error has occured while reading from local DB'));
                  }
                  return LoadingBar;
                });
          }
          return LoadingBar;
        });
  }
}
