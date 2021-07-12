import 'package:flutter/material.dart';
import 'dart:io' show Platform; // OS Detection
import 'package:flutter/foundation.dart' show kIsWeb; // Web detection
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaroom/fakegen.dart';
import '../components/contactView.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../utils/types.dart';
import '../../blocs/chats.dart';

class ChatPage extends StatefulWidget {
  final userId, name, image;
  ChatPage({required this.userId, this.name, this.image});
  ChatPageState createState() => new ChatPageState();
}

class ChatPageState extends State<ChatPage> {
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

  Widget _buildMessagesView(List<ChatMessage> msgs) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
              child: ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.only(top: 15.0),
                  itemCount: msgs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _buildMessage(msgs[msgs.length - 1 - index]);
                  }))
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, String data) {
    // TODO: Send msg content through web socket, receive including msgId into stream of websocket
    // The above mechanism should autobuild view of user
    Provider.of<WebSocketChannel>(context, listen: false).sink.add(data);
    // TODO: Get msg id by sending data to server
    BlocProvider.of<UserChatCubit>(context, listen: false).insertTextMessage(
        msgId: getMsgId(),
        fromUser: Provider.of<UserId>(context, listen: false),
        content: data);
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
                  otherUser: widget.userId,
                  db: RepositoryProvider.of<AppDb>(context),
                  initialState: snapshot.data!);
              webSocketSubscription =
                  Provider.of<WebSocketChannel>(context, listen: false)
                      .stream
                      .listen((data) {
                // TODO: Handle text and media messages
                // TODO: Handle from and to User Id check
                cubit.insertTextMessage(
                    msgId: getMsgId(), fromUser: getUserId(), content: data);
              }, onError: (error) {
                print(error);
                return SnackBar(
                    content: Text(
                        'Error has occured while receiving from websocket'));
              });
              return cubit;
            }, child: Builder(builder: (context) {
              return WillPopScope(
                child: Stack(children: <Widget>[
                  Scaffold(
                      appBar: AppBar(
                        titleSpacing: 0,
                        title: ListTile(
                          onTap: () => _showContact(context),
                          contentPadding:
                              EdgeInsets.only(left: 0.0, right: 0.0),
                          tileColor: Colors.transparent,
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[350],
                            foregroundImage: NetworkImage('${widget.image}'),
                            backgroundImage:
                                AssetImage('assets/no-profile.png'),
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
                            BlocBuilder<UserChatCubit, List<ChatMessage>>(
                                builder: (BuildContext context,
                                        List<ChatMessage> state) =>
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
                                                    LogicalKeyboardKey.enter) &&
                                                !event.isShiftPressed) {
                                              String data =
                                                  inputController.text;
                                              inputController.clear();
                                              _sendMessage(
                                                  context, data.trim());
                                            }
                                          }
                                        },
                                        child: TextField(
                                          maxLines: null,
                                          controller: inputController,
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          onEditingComplete: () {
                                            String data = inputController.text;
                                            inputController.clear();
                                            _sendMessage(context, data.trim());
                                          },
                                          decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                              hintText: 'Type a message'),
                                        ))),
                                IconButton(
                                    onPressed: () {
                                      String data = inputController.text;
                                      inputController.clear();
                                      _sendMessage(context, data.trim());
                                    },
                                    icon: Icon(Icons.send))
                              ],
                            ),
                            (isShowSticker ? buildSticker() : Container())
                          ]))
                ]),
                onWillPop: onBackPress,
              );
            }));
          } else if (snapshot.hasError) {
            print(snapshot.error);
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
