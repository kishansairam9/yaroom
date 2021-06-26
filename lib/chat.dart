import 'package:flutter/material.dart';
import 'package:faker/faker.dart';
import 'package:badges/badges.dart';
import 'dart:math';

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
    return ListView(
      children: widget._chats,
    );
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
  
  final myController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    isShowSticker = false;
    for (int i = 0; i < random; i++) {
      sender.add(Random().nextInt(2));
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
      margin: isMe
          ? EdgeInsets.only(top: 7.0, bottom: 7.0, left: 80.0)
          : EdgeInsets.only(top: 7.0, bottom: 7.0, right: 80.0),
      padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
      decoration: BoxDecoration(
        borderRadius: isMe
            ? BorderRadius.only(
                topLeft: Radius.circular(15.0),
                bottomLeft: Radius.circular(15.0))
            : BorderRadius.only(
                topRight: Radius.circular(15.0),
                bottomRight: Radius.circular(15.0)),
        color: isMe ? Colors.blueAccent : Colors.blueGrey,
      ),
      child: Column(
        children: [
          Text()
          Text(msgs[index]),
        ],
      ),
    );
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
    return WillPopScope(
      child: Stack(children: <Widget>[
        Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: ListTile(
                contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
                tileColor: Colors.transparent,
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[350],
                  foregroundImage: NetworkImage('${widget.image}'),
                  backgroundImage: AssetImage('assets/no-profile.png'),
                ),
                title: Text(widget.name),
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
                          child: TextField(
                        controller: myController,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Type a message'),
                      )),
                      IconButton(
                          onPressed: () {
                            msgs.insert(0, myController.text);
                            sender.insert(0, 1);
                            myController.clear();
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
    return Card(
      child: ListTile(
        onTap: _showChat,
        leading: CircleAvatar(
          backgroundColor: Colors.grey[350],
          foregroundImage: NetworkImage('${widget.image}'),
          backgroundImage: AssetImage('assets/no-profile.png'),
        ),
        title: Text(widget.name),
        subtitle: _lastChat.isEmpty ? null : Text(_lastChat),
        trailing: _unread > 0
            ? Badge(
                // TODO: Badge sizes differ for 1 digit and 2, 3 digits etc, fix this incositency
                // Pad left space doesn't help
                badgeContent: Text('$_unread'),
                badgeColor: Theme.of(context).accentColor,
                padding: EdgeInsets.all(10),
                // TODO: Badges float around when puled from bottom to top agressively, should animate even slightly
              )
            : null,
      ),
    );
  }
}
