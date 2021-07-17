import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io' show Platform; // OS Detection
import 'package:flutter/foundation.dart' show kIsWeb; // Web detection
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaroom/fakegen.dart';
import '../components/contactView.dart';
import 'package:provider/provider.dart';
import '../../utils/websocket.dart';
import '../../utils/types.dart';
import '../../blocs/groupChats.dart';

class GroupChatPage extends StatefulWidget {
  final groupId, name, image;
  GroupChatPage({required this.groupId, this.name, this.image});
  GroupChatPageState createState() => new GroupChatPageState();
}

class GroupChatPageState extends State<GroupChatPage> {
  bool isShowSticker = false;

  final inputController = TextEditingController();
  late final webSocketSubscription;

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
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  _buildMessage(BuildContext context, GroupChatMessage msg) {
    final bool isMe = msg.fromUser == Provider.of<UserId>(context);
    return Container(
        padding: EdgeInsets.only(left: 5.0, right: 14, top: 10, bottom: 10),
        child: Align(
          alignment: isMe ? Alignment.bottomRight : Alignment.topLeft,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                !isMe?
                     Flexible(
                        flex: 1,
                        child: Padding(padding: EdgeInsets.only(right: 5.0),child:CircleAvatar(
                        backgroundColor: Colors.grey[350],
                        foregroundImage: widget.image == null
                            ? null
                            : NetworkImage('${widget.image}'),
                        backgroundImage: AssetImage('assets/no-profile.png'),
                        radius: 20.0,
                      )))
                    : Flexible(flex:1, child:Container()),
                Flexible(
                  flex: 10,
                  child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                      margin: isMe
                          ? EdgeInsets.only(top: 7.0, bottom: 7.0, left: 70.0)
                          : EdgeInsets.only(top: 7.0, bottom: 7.0, right: 70.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        color: isMe ? Colors.blueAccent : Colors.blueGrey,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          !isMe
                              ? Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(Provider.of<List<User>>(context,
                                          listen: false)
                                      .where((element) =>
                                          element.userId == msg.fromUser)
                                      .toList()[0]
                                      .name, style: TextStyle(color: Colors.grey, fontSize: Theme.of(context).textTheme.overline!.fontSize),))
                              : Container(),
                          SizedBox(
                            height: 10,
                          ),
                          Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Text(
                                msg.content!,
                                textAlign:
                                    isMe ? TextAlign.right : TextAlign.left,
                                style: TextStyle(color: Colors.white),
                              )),
                        ],
                      )),
                )
              ]),
        ));
  }

  // To display profile
  _showContact(context, var user) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext c) {
          return ViewContact(user);
        });
  }

  Widget _buildMessagesView(List<GroupChatMessage> msgs) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
              child: ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.only(top: 15.0),
                  itemCount: msgs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _buildMessage(
                        context, msgs[msgs.length - 1 - index]);
                  }))
        ],
      ),
    );
  }

  void _sendMessage(
      {required BuildContext context,
      String? content,
      String? media,
      int? replyTo}) {
    assert(!(media == null && content == null));
    Provider.of<WebSocketWrapper>(context, listen: false).add(jsonEncode({
      'type': 'GroupChatMessage',
      'groupId': widget.groupId,
      'fromUser': Provider.of<UserId>(context, listen: false),
      'content': content,
      'time': DateTime.now().toIso8601String(),
      'media': media,
      'replyTo': replyTo,
    }));
  }

  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
        future: RepositoryProvider.of<AppDb>(context)
            .getGroupMembers(groupID: widget.groupId)
            .get(),
        builder:
            (BuildContext _, AsyncSnapshot<List<User>> groupMembersSnapshot) {
          if (groupMembersSnapshot.hasData) {
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
                          webSocketSubscription = Provider.of<WebSocketWrapper>(
                                  context,
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
                              content: data['content'],
                              media: data['media'],
                              replyTo: data['replyTo'],
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
                        return WillPopScope(
                          child: Stack(children: <Widget>[
                            Scaffold(
                                endDrawer: Drawer(
                                    child: ListView(
                                  padding: EdgeInsets.zero,
                                  children: [
                                    DrawerHeader(
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                          ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.grey[350],
                                              foregroundImage: NetworkImage(
                                                  '${widget.image}'),
                                              backgroundImage: AssetImage(
                                                  'assets/no-profile.png'),
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              Column(
                                                children: [
                                                  IconButton(
                                                      onPressed: () => {},
                                                      tooltip: "Call",
                                                      icon: Icon(Icons.call)),
                                                  Text("Call")
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  IconButton(
                                                      onPressed: () => {},
                                                      tooltip: "Video Call",
                                                      icon: Icon(Icons
                                                          .video_call_sharp)),
                                                  Text("Video")
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  IconButton(
                                                      onPressed: () => {},
                                                      tooltip:
                                                          "Pinned Messages",
                                                      icon:
                                                          Icon(Icons.push_pin)),
                                                  Text("Pins")
                                                ],
                                              ),
                                            ],
                                          ),
                                        ])),
                                    ...groupMembersSnapshot.data!.map((User
                                            e) =>
                                        // for (var i = 0; i < widget.memberCount; i++)
                                        ListTile(
                                            onTap: () =>
                                                _showContact(context, e),
                                            tileColor: Colors.transparent,
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.grey[350],
                                              foregroundImage: NetworkImage(
                                                  '${e.profileImg}'),
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
                                          onPressed: () =>
                                              Navigator.pop(context),
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
                                              foregroundImage: NetworkImage(
                                                  '${widget.image}'),
                                              backgroundImage: AssetImage(
                                                  'assets/no-profile.png'),
                                            ),
                                            title: Text(
                                              widget.name,
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          )),
                                  actions: <Widget>[
                                    IconButton(
                                      onPressed: () => {},
                                      icon: Icon(Icons.phone),
                                      tooltip: 'Call',
                                    ),
                                    IconButton(
                                      onPressed: () => {},
                                      icon: Icon(Icons.more_vert),
                                      tooltip: 'More',
                                    )
                                  ],
                                ),
                                body: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      BlocBuilder<GroupChatCubit,
                                              List<GroupChatMessage>>(
                                          builder: (BuildContext context,
                                                  List<GroupChatMessage>
                                                      state) =>
                                              _buildMessagesView(state)),
                                      Row(
                                        children: [
                                          Expanded(
                                              child: RawKeyboardListener(
                                                  focusNode: FocusNode(),
                                                  onKey: (RawKeyEvent event) {
                                                    if (kIsWeb ||
                                                        Platform.isMacOS ||
                                                        Platform.isLinux ||
                                                        Platform.isWindows) {
                                                      // Submit on Enter and new line on Shift + Enter only on desktop devices or Web
                                                      if (event.isKeyPressed(
                                                              LogicalKeyboardKey
                                                                  .enter) &&
                                                          !event
                                                              .isShiftPressed) {
                                                        String data =
                                                            inputController
                                                                .text;
                                                        inputController.clear();
                                                        // Bug fix for stray new line after Pressing Enter
                                                        Future.delayed(
                                                            Duration(
                                                                milliseconds:
                                                                    100),
                                                            () =>
                                                                inputController
                                                                    .clear());
                                                        _sendMessage(
                                                            context: context,
                                                            content:
                                                                data.trim());
                                                      }
                                                    }
                                                  },
                                                  child: TextField(
                                                    maxLines: null,
                                                    controller: inputController,
                                                    textCapitalization:
                                                        TextCapitalization
                                                            .sentences,
                                                    onEditingComplete: () {
                                                      String data =
                                                          inputController.text;
                                                      inputController.clear();
                                                      _sendMessage(
                                                          context: context,
                                                          content: data.trim());
                                                    },
                                                    decoration: InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        hintText:
                                                            'Type a message'),
                                                  ))),
                                          IconButton(
                                              onPressed: () {
                                                String data =
                                                    inputController.text;
                                                inputController.clear();
                                                _sendMessage(
                                                    context: context,
                                                    content: data.trim());
                                              },
                                              icon: Icon(Icons.send))
                                        ],
                                      ),
                                      (isShowSticker
                                          ? buildSticker()
                                          : Container())
                                    ]))
                          ]),
                          onWillPop: onBackPress,
                        );
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

  // create a emoji keyboard
  Widget buildSticker() {
    return Container(
      margin: const EdgeInsets.all(10.0),
      color: Colors.amber[600],
      width: 100.0,
      height: 5.0,
    );
  }
}
