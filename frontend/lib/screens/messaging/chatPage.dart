import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaroom/screens/components/msgBox.dart';
import '../components/contactView.dart';
import 'package:provider/provider.dart';
import '../../utils/messageExchange.dart';
import '../../utils/types.dart';
import '../../blocs/chats.dart';

class ChatPage extends StatefulWidget {
  late final String userId, name;
  late final String? image;

  ChatPage(ChatPageArguments args) {
    this.userId = args.userId;
    this.name = args.name;
    this.image = args.image;
  }
  ChatPageState createState() => new ChatPageState();
}

class ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state.toString());
    switch (state) {
      case AppLifecycleState.resumed:
        Navigator.of(context).pushReplacementNamed('/chat',
            arguments: ChatPageArguments(
                name: widget.name, userId: widget.userId, image: widget.image));
        break;
      default:
        break;
    }
  }

  Widget _buildSingleMessage(ChatMessage msg, bool isMe) {
    print(msg);
    if (msg.media != null && msg.content != null) {
      print('hi');
      // print(msg.media!);
      return Column(
        children: [
          Text(
            msg.media!, // Using unicode space is imp as flutter engine trims otherwise
            textAlign: isMe ? TextAlign.right : TextAlign.left,
            style: TextStyle(color: Colors.white),
          ),
          Text(
            msg.content!, // Using unicode space is imp as flutter engine trims otherwise
            textAlign: isMe ? TextAlign.right : TextAlign.left,
            style: TextStyle(color: Colors.white),
          ),
        ],
      );
    }
    if (msg.media != null && msg.content == null) {
      print('hi');
      // print(msg.media!);
      return Text(
        msg.media!, // Using unicode space is imp as flutter engine trims otherwise
        textAlign: isMe ? TextAlign.right : TextAlign.left,
        style: TextStyle(color: Colors.white),
      );
    }
    if (msg.media == null && msg.content != null) {
      print("hola");
      print(msg.content!);
      return Text(
        msg.content!, // Using unicode space is imp as flutter engine trims otherwise
        textAlign: isMe ? TextAlign.right : TextAlign.left,
        style: TextStyle(color: Colors.white),
      );
    }
    return Container();
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
                child: _buildSingleMessage(msg, isMe)),
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
              profileImg: widget.image));
        });
  }

  Widget _buildMessagesView(List<ChatMessage> msgs) {
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
                    return _buildMessage(msgs[msgs.length - 1 - index],
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
    // print("hi");
    // print(Provider.of<FilePickerDetails>(context, listen: false).getMedia());
    // print(media);
    // print(BlocProvider.of<FilePickerCubit>(context).state.filesAttached);
    if (media != null && media.keys.length == 0) media = null;
    if (content == '') content = null;
    if (media == null && content == null) {
      return;
    }
    print("hello me here");
    print(media);
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
    // Provider.of<FilePickerDetails>(context, listen: false)
    //     .updateState(Map(), 0);
    BlocProvider.of<FilePickerCubit>(context, listen: false)
        .updateFilePicker(media: Map(), i: 0);
  }

  Future<bool> onBackPress() {
    Navigator.of(context).pop();
    return Future.value(false);
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
                return (data['fromUser'] == widget.userId ||
                    data['toUser'] == widget.userId);
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
                        foregroundImage: widget.image == null
                            ? null
                            : NetworkImage('${widget.image}'),
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
