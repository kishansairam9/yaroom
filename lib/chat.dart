import 'package:flutter/material.dart';
import 'package:faker/faker.dart';
import 'dart:math';
import 'dart:io' show Platform; // OS Detection
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart'; // Web detection
import 'contact.dart';

class ChatView extends StatefulWidget {
  final _chats = <ProfileView>[];

  get tiles => _chats;

  ChatView() {
    for (int i = 0; i < 30; i++) {
      _chats.add(ProfileView());
    }
  }

  @override
  ChatViewState createState() => ChatViewState();
}

class ChatViewState extends State<ChatView> {
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

class ProfileView extends StatefulWidget {
  late final _image;
  late final String _name;

  get image => _image;
  get name => _name;

  ProfileView() {
    _image = faker.image.image(
        width: 150, height: 150, keywords: ['people', 'nature'], random: true);
    _name = faker.person.name();
  }

  @override
  ProfileViewState createState() => ProfileViewState();
}

class ChatPage extends StatefulWidget {
  final name, image;
  ChatPage({required this.name, this.image});
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
      // msgs.add('Hola');
      msgs.add(getRandomString(Random().nextInt(100) + 1));
      // datetime.add(RandomDate.withRange(2010, 2021));
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
  _showContact(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext c) {
          return ViewContact(widget);
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
            appBar: AppBar(
              titleSpacing: 0,
              title: ListTile(
                onTap: () => _showContact(context),
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
              ),
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

dynamic getProfileTileComponent(BuildContext context, void Function()? onTap,
    dynamic image, dynamic title, dynamic subtitle, dynamic _unread) {
  return ListTile(
    minVerticalPadding: 25.0,
    onTap: onTap,
    leading: CircleAvatar(
      backgroundColor: Colors.grey[350],
      foregroundImage: NetworkImage(image),
      backgroundImage: AssetImage('assets/no-profile.png'),
      radius: 28.0,
    ),
    title: Text(title),
    subtitle: subtitle,
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
}

class ProfileViewState extends State<ProfileView> {
  int _unread = 0;
  String _lastChat = '';

  ProfileViewState() {
    _unread = Random().nextInt(20);
  }

  void _showChat() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      return ChatPage(name: widget.name, image: widget.image);
    }));
  }

  @override
  Widget build(BuildContext context) {
    // return Card(
    return getProfileTileComponent(context, _showChat, widget.image,
        widget.name, _lastChat.isEmpty ? null : Text(_lastChat), _unread);
    // );
  }
}
