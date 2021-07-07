import 'package:flutter/material.dart';
import 'dart:io' show Platform; // OS Detection
import 'package:flutter/foundation.dart' show kIsWeb; // Web detection
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaroom/fakegen.dart';
import '../components/contactView.dart';
import 'package:provider/provider.dart';
import '../../utils/types.dart';

class ChatPage extends StatefulWidget {
  final userId, name, image;
  ChatPage({required this.userId, this.name, this.image});
  ChatPageState createState() => new ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  late bool isShowSticker;
  late Stream<List<ChatMessage>>
      dataStream; // TODO: REMOVE USAGE STREAM AND USE BLOC

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
    dataStream = RepositoryProvider.of<AppDb>(context)
        .getUserChat(otherUser: widget.userId)
        .watch(); // TODO: Remove this and use BLOC
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

  _buildMessage(ChatMessage msg) {
    final bool isMe = msg.fromUser == Provider.of<UserId>(context);
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
              msg.content!,
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

  Widget showMessages(List<ChatMessage> msgs) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
              child: ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.only(top: 15.0),
                  itemCount: msgs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _buildMessage(msgs[index]);
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
                  StreamBuilder(
                      stream: dataStream,
                      builder: (BuildContext context,
                          AsyncSnapshot<List<ChatMessage>> snapshot) {
                        if (snapshot.hasData) {
                          return showMessages(snapshot.data!);
                        } else if (snapshot.hasError) {
                          print(snapshot.data);
                          return SnackBar(
                              content: Text(
                                  'Error has occured while reading from DB'));
                        }
                        return Container();
                      }),
                  Row(
                    children: [
                      Expanded(
                          child: RawKeyboardListener(
                              focusNode: FocusNode(),
                              onKey: (RawKeyEvent event) async {
                                if (kIsWeb ||
                                    Platform.isMacOS ||
                                    Platform.isLinux ||
                                    Platform.isWindows) {
                                  // Submit on Enter and new line on Shift + Enter only on desktop devices or Web
                                  if (event.isKeyPressed(
                                          LogicalKeyboardKey.enter) &&
                                      !event.isShiftPressed) {
                                    // TODO: EXTRACT SAME CALL INTO ONE THING 3 times duplicated
                                    // TODO: Get msg id by sending data to server
                                    String data = inputController.text;
                                    inputController.clear();
                                    await RepositoryProvider.of<AppDb>(context)
                                        .insertTextMessage(
                                            msgId: getMsgId(),
                                            fromUser: Provider.of<UserId>(
                                                context,
                                                listen: false),
                                            toUser: widget.userId,
                                            time: DateTime.now(),
                                            content: data.trim());
                                  }
                                }
                              },
                              child: TextField(
                                maxLines: null,
                                controller: inputController,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                onEditingComplete: () async {
                                  // TODO: EXTRACT SAME CALL INTO ONE THING 3 times duplicated
                                  // TODO: Get msg id by sending data to server
                                  String data = inputController.text;
                                  inputController.clear();
                                  await RepositoryProvider.of<AppDb>(context)
                                      .insertTextMessage(
                                          msgId: getMsgId(),
                                          fromUser: Provider.of<UserId>(context,
                                              listen: false),
                                          toUser: widget.userId,
                                          time: DateTime.now(),
                                          content: data.trim());
                                },
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Type a message'),
                              ))),
                      IconButton(
                          onPressed: () async {
                            // TODO: EXTRACT SAME CALL INTO ONE THING 3 times duplicated
                            // TODO: Get msg id by sending data to server
                            String data = inputController.text;
                            inputController.clear();
                            await RepositoryProvider.of<AppDb>(context)
                                .insertTextMessage(
                                    msgId: getMsgId(),
                                    fromUser: Provider.of<UserId>(context,
                                        listen: false),
                                    toUser: widget.userId,
                                    time: DateTime.now(),
                                    content: data.trim());
                            var k = await RepositoryProvider.of<AppDb>(context)
                                .searchChatMessages(query: data, limit: 5)
                                .get();
                            for (var x in k) {
                              print(x.fromUser);
                              print(x.content);
                            }
                            print(k);
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
