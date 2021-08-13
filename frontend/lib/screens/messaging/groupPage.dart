import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';
import 'dart:convert';
import 'dart:io' show Platform; // OS Detection
import 'package:flutter/foundation.dart' show kIsWeb; // Web detection
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaroom/screens/components/msgBox.dart';
import '../components/contactView.dart';
import '../components/searchDelegate.dart';
import 'package:provider/provider.dart';
import '../../utils/messageExchange.dart';
import '../../utils/types.dart';
import '../../blocs/groupChats.dart';

class GroupChatPage extends StatefulWidget {
  late final String groupId, name;
  late final String? image;

  GroupChatPage(GroupChatPageArguments args) {
    this.groupId = args.groupId;
    this.name = args.name;
    this.image = args.image;
  }
  GroupChatPageState createState() => new GroupChatPageState();
}

class GroupChatPageState extends State<GroupChatPage>
    with WidgetsBindingObserver {
  final inputController = TextEditingController();
  late final webSocketSubscription;

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
    inputController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state.toString());
    switch (state) {
      case AppLifecycleState.resumed:
        Navigator.of(context).pushReplacementNamed('/groupchat',
            arguments: GroupChatPageArguments(
                name: widget.name,
                groupId: widget.groupId,
                image: widget.image));
        break;
      default:
        break;
    }
  }

  // handling backPress when emoji keyboard is implemented
  Future<bool> onBackPress() {
    Navigator.of(context).pop();
    return Future.value(false);
  }

  Widget buildSingleMsg(msg) {
    if (msg.media != null && msg.content != null) {
      return Column(
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Text(
                msg.media!,
                textAlign: TextAlign.left,
                style: TextStyle(color: Colors.white),
              )),
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
    if (msg.media != null && msg.content == null) {
      return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            msg.media!,
            textAlign: TextAlign.left,
            style: TextStyle(color: Colors.white),
          ));
    }
    if (msg.media == null && msg.content != null) {
      return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            msg.content!,
            textAlign: TextAlign.left,
            style: TextStyle(color: Colors.white),
          ));
    }
    return Container();
  }

  _buildMessage(BuildContext context, GroupChatMessage msg, bool prevIsSame,
      DateTime? prependDay) {
    var curUser = Provider.of<List<User>>(context, listen: false)
        .where((element) => element.userId == msg.fromUser)
        .toList()[0];
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
                        buildSingleMsg(msg),
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

  // To display profile
  _showContact(context, var user) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext c) {
          return ViewContact(user);
        });
  }

  final GlobalKey<ScaffoldState> _scaffoldkey = new GlobalKey();

  Widget _buildMessagesView(List<GroupChatMessage> msgs) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
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
                  }))
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
        .updateFilePicker(media: Map(), i: 0);
  }

  DrawerHeader _getDrawerHeader() {
    return DrawerHeader(
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[350],
          foregroundImage: NetworkImage('${widget.image}'),
          backgroundImage: AssetImage('assets/no-profile.png'),
        ),
        tileColor: Colors.transparent,
        trailing: IconButton(
          onPressed: () => {},
          icon: Icon(Icons.more_vert),
          tooltip: "More",
        ),
        title: Text(
          widget.name,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 20),
        ),
        // subtitle: Text(widget.name),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              IconButton(
                  onPressed: () => {}, tooltip: "Call", icon: Icon(Icons.call)),
              Text("Call")
            ],
          ),
          Column(
            children: [
              IconButton(
                  onPressed: () => {},
                  tooltip: "Video Call",
                  icon: Icon(Icons.video_call_sharp)),
              Text("Video")
            ],
          ),
          Column(
            children: [
              IconButton(
                  onPressed: () => {},
                  tooltip: "Pinned Messages",
                  icon: Icon(Icons.push_pin)),
              Text("Pins")
            ],
          ),
        ],
      ),
    ]));
  }

  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
        future: RepositoryProvider.of<AppDb>(context)
            .getGroupMembers(groupID: widget.groupId)
            .get(),
        builder:
            (BuildContext _, AsyncSnapshot<List<User>> groupMembersSnapshot) {
          if (groupMembersSnapshot.hasData) {
            print(groupMembersSnapshot.data);
            return FutureBuilder(
                future: RepositoryProvider.of<AppDb>(context)
                    .getGroupChat(groupId: widget.groupId)
                    .get(),
                builder: (BuildContext _,
                    AsyncSnapshot<List<GroupChatMessage>> groupChatSnapshot) {
                  if (groupChatSnapshot.hasData) {
                    return MultiProvider(
                      providers: [
                        Provider<List<User>>(
                            create: (_) => groupMembersSnapshot.data!),
                        BlocProvider(create: (context) {
                          var cubit = GroupChatCubit(
                              groupId: widget.groupId,
                              initialState: groupChatSnapshot.data!);
                          webSocketSubscription =
                              Provider.of<MessageExchangeStream>(context,
                                      listen: false)
                                  .stream
                                  .where((encodedData) {
                            var data = jsonDecode(encodedData);
                            return data['groupId'] == widget.groupId;
                          }).listen((encodedData) {
                            var data = jsonDecode(encodedData);
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
                        return Scaffold(
                            key: _scaffoldkey,
                            endDrawer: Drawer(
                                child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                _getDrawerHeader(),
                                ...groupMembersSnapshot.data!.map((User e) =>
                                    // for (var i = 0; i < widget.memberCount; i++)
                                    ListTile(
                                        onTap: () => _showContact(context, e),
                                        tileColor: Colors.transparent,
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.grey[350],
                                          foregroundImage:
                                              NetworkImage('${e.profileImg}'),
                                          backgroundImage: AssetImage(
                                              'assets/no-profile.png'),
                                        ),
                                        title: Text(
                                          e.name,
                                        )))
                              ],
                            )),
                            appBar: AppBar(
                              leading: Builder(
                                  builder: (context) => IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: Icon(Icons.arrow_back))),
                              titleSpacing: 0,
                              title: Builder(
                                  builder: (context) => ListTile(
                                        onTap: () => Scaffold.of(context)
                                            .openEndDrawer(),
                                        contentPadding: EdgeInsets.only(
                                            left: 0.0, right: 0.0),
                                        tileColor: Colors.transparent,
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.grey[350],
                                          foregroundImage:
                                              NetworkImage('${widget.image}'),
                                          backgroundImage: AssetImage(
                                              'assets/no-profile.png'),
                                        ),
                                        title: Text(
                                          widget.name,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      )),
                              actions: <Widget>[
                                IconButton(
                                  onPressed: () => {
                                    showSearch(
                                        context: context,
                                        delegate: ExchangeSearchDelegate(
                                            accessToken: Provider.of<UserId>(
                                                context,
                                                listen:
                                                    false), // Passing userId for now TODO FIX ONCE FIXED AUTH0 BUG
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
                  return CircularProgressIndicator();
                });
          } else if (groupMembersSnapshot.hasError) {
            print(groupMembersSnapshot.error);
            return SnackBar(
                content: Text('Error has occured while reading from local DB'));
          }
          return CircularProgressIndicator();
        });
  }
}
