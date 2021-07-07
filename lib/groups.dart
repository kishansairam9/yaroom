import 'package:flutter/material.dart';
import 'package:faker/faker.dart';
import 'dart:math';
import 'dart:io' show Platform; // OS Detection
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart'; // Web detection
import 'package:yaroom/chat.dart';
import 'contact.dart';

class GroupChatView extends StatefulWidget {
  final _chats = <GroupProfileView>[];

  get tiles => _chats;

  GroupChatView() {
    for (int i = 0; i < 30; i++) {
      _chats.add(GroupProfileView());
    }
  }

  @override
  GroupChatViewState createState() => GroupChatViewState();
}

class GroupChatViewState extends State<GroupChatView> {
  @override
  Widget build(BuildContext context) {
    // return ListView(
    //   children: widget._chats,
    // );
    return ListView(
        children: ListTile.divideTiles(
      context: context,
      tiles: widget._chats,
    ).toList());
  }
}

class GroupProfileView extends StatefulWidget {
  late final _image;
  late final String _name;
  late final _members;
  final _memberCount = Random().nextInt(20) + 2;

  get image => _image;
  get name => _name;
  get members => _members;
  get memberCount => _memberCount;

  GroupProfileView() {
    _image = faker.image.image(
        width: 150,
        height: 150,
        keywords: ['office', 'corporate'],
        random: true);
    _name = faker.company.name();
    _members = [for (var i = 0; i < _memberCount; i++) ProfileView()];
  }

  @override
  GroupProfileViewState createState() => GroupProfileViewState();
}

class ChatPage extends StatefulWidget {
  final name, image, members, memberCount;
  ChatPage(
      {required this.name,
      this.image,
      required this.members,
      required this.memberCount});
  ChatPageState createState() => new ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  late bool isShowSticker;
  late var msgs = <String>[];
  // late var datetime = <DateTime>[];
  late var sender = <int>[];
  final random = Random().nextInt(20) + 1;
  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890 ';
  Random _rnd = Random();
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  final inputController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    inputController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    isShowSticker = false;
    for (int i = 0; i < random; i++) {
      sender.add(Random().nextInt(2));
      msgs.add(getRandomString(Random().nextInt(100) + 1));
    }
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

  _buildMessage(int index, bool isMe) {
    return Container(
        padding: EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
        child: Align(
          alignment: isMe ? Alignment.bottomRight : Alignment.topLeft,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
            margin: isMe
                ? EdgeInsets.only(top: 7.0, bottom: 7.0, left: 70.0)
                : EdgeInsets.only(top: 7.0, bottom: 7.0, right: 70.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              color: isMe ? Colors.blueAccent : Colors.blueGrey,
            ),
            child: Text(
              msgs[index],
              textAlign: isMe ? TextAlign.right : TextAlign.left,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ));
  }

  // To display profile
  _showContact(context, int index) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext c) {
          return ViewContact(widget.members[index]);
        });
  }

  Widget showMessages() {
    return Expanded(
      child: Column(
        children: [
          Expanded(
              child: ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.only(top: 15.0),
                  itemCount: msgs.length,
                  itemBuilder: (BuildContext context, int index) {
                    final bool isMe = sender[index] == 1;
                    return _buildMessage(index, isMe);
                  }))
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    inputController.clear();
    return WillPopScope(
      child: Stack(children: <Widget>[
        Scaffold(
            endDrawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                        ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[350],
                              foregroundImage: NetworkImage('${widget.image}'),
                              backgroundImage:
                                  AssetImage('assets/no-profile.png'),
                            ),
                            // contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
                            tileColor: Colors.transparent,
                            trailing: IconButton(
                              onPressed: () => {},
                              icon: Icon(Icons.more_vert),
                              tooltip: "More",
                            ),
                            title:
                                //  FittedBox(
                                // fit: BoxFit.fitWidth, child:
                                Text(
                              widget.name,
                              style: TextStyle(fontSize: 20),
                            )
                            // ),
                            ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                      ])),
                  for (var i = 0; i < widget.memberCount; i++)
                    ListTile(
                        onTap: () => _showContact(context, i),
                        tileColor: Colors.transparent,
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[350],
                          foregroundImage:
                              NetworkImage('${widget.members[i].image}'),
                          backgroundImage: AssetImage('assets/no-profile.png'),
                        ),
                        title: Text(
                          widget.members[i].name,
                        ))
                ],
              ),
            ),
            appBar: AppBar(
              leading: Builder(
                  builder: (context) => IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back))),
              titleSpacing: 0,
              title: Builder(
                  builder: (context) => ListTile(
                        onTap: () => Scaffold.of(context).openEndDrawer(),
                        contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
                        tileColor: Colors.transparent,
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[350],
                          foregroundImage: NetworkImage('${widget.image}'),
                          backgroundImage: AssetImage('assets/no-profile.png'),
                        ),
                        title: Text(
                          widget.name,
                          style: TextStyle(color: Colors.white),
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
                  icon: Icon(Icons.video_call),
                  tooltip: 'Video Call',
                ),
                Builder(
                    builder: (context) => IconButton(
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
                          icon: Icon(Icons.people),
                          tooltip: 'Member List',
                        ))
              ],
            ),
            body: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  showMessages(),
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
                                          LogicalKeyboardKey.enter) &&
                                      !event.isShiftPressed) {
                                    msgs.insert(0, inputController.text);
                                    sender.insert(0, 1);
                                    setState(() {});
                                  }
                                }
                              },
                              child: TextField(
                                maxLines: null,
                                controller: inputController,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                onEditingComplete: () {
                                  msgs.insert(0, inputController.text);
                                  sender.insert(0, 1);
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Type a message'),
                              ))),
                      IconButton(
                          onPressed: () {
                            msgs.insert(0, inputController.text);
                            sender.insert(0, 1);
                            setState(() {});
                          },
                          icon: Icon(Icons.send))
                    ],
                  ),
                  (isShowSticker ? buildSticker() : Container())
                ]))
      ]),
      onWillPop: onBackPress,
    );
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

class GroupProfileViewState extends State<GroupProfileView> {
  int _unread = 0;
  String _lastChat = '';

  GroupProfileViewState() {
    _unread = Random().nextInt(20);
  }

  void _showChat() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      return ChatPage(
          name: widget.name,
          image: widget.image,
          members: widget.members,
          memberCount: widget.memberCount);
    }));
  }

  @override
  Widget build(BuildContext context) {
    // return Card(
    return ListTile(
      minVerticalPadding: 25.0,
      onTap: _showChat,
      leading: CircleAvatar(
        backgroundColor: Colors.grey[350],
        foregroundImage: NetworkImage('${widget.image}'),
        backgroundImage: AssetImage('assets/no-profile.png'),
        radius: 28.0,
      ),
      title: Text(widget.name),
      subtitle: _lastChat.isEmpty ? null : Text(_lastChat),
      trailing: _unread > 0
          ?
          // TODO: Badges float around when puled from bottom to top agressively, should animate even slightly
          MaterialButton(
              onPressed: () {},
              color: Colors.blueGrey[400],
              child: Text(
                '$_unread',
                style: TextStyle(color: Theme.of(context).accentColor),
              ),
              // padding: EdgeInsets.all(5),
              shape: CircleBorder(),
            )
          : null,
    );
    // );
  }
}
