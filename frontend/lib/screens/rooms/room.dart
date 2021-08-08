import 'dart:convert';
import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yaroom/blocs/rooms.dart';
import '../components/msgBox.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/messageExchange.dart';
import '../../utils/types.dart';
import '../../utils/guidePages.dart';

class Room extends StatefulWidget {
  @override
  RoomState createState() => RoomState();
  late final String roomId;
  // late final String roomName;
  late final String? channelId;
  Room({required this.roomId, this.channelId});
}

class RoomState extends State<Room> {
  //  Current State of InnerDrawerState
  late final webSocketSubscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller & subscription when the widget is disposed.
    webSocketSubscription.cancel();
    super.dispose();
  }

  Widget buildSingleMsg(RoomsMessage msg, var curUser, var dateStr, var time) {
    if (msg.media != null && msg.content != null) {
      return Row(
        children: [
          Flexible(
              flex: 1,
              // child: Padding(
              //     padding: EdgeInsets.only(right: 5.0, top: 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: CircleAvatar(
                  backgroundColor: Colors.grey[350],
                  foregroundImage: curUser.profileImg == null
                      ? null
                      : NetworkImage('${curUser.profileImg}'),
                  backgroundImage: AssetImage('assets/no-profile.png'),
                  radius: 20.0,
                ),
              )
              // )
              ),
          Flexible(
              flex: 10,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  // margin: EdgeInsets.only(top: 7.0, bottom: 7.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                    // color: Colors.blueGrey,
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                            alignment: Alignment.topLeft,
                            child: Row(
                              children: [
                                Text(
                                  curUser.name,
                                  style: TextStyle(
                                      // color: Colors.grey,
                                      fontSize: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .fontSize,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  dateStr + " at " + time,
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .fontSize),
                                )
                              ],
                            )),
                        SizedBox(
                          height: 10,
                        ),
                        Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                msg.content!,
                                textAlign: TextAlign.left,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                msg.media!,
                                textAlign: TextAlign.left,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ]))),
        ],
      );
    }
    if (msg.media != null && msg.content == null) {
      return Row(
        children: [
          Flexible(
              flex: 1,
              // child: Padding(
              //     padding: EdgeInsets.only(right: 5.0, top: 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: CircleAvatar(
                  backgroundColor: Colors.grey[350],
                  foregroundImage: curUser.profileImg == null
                      ? null
                      : NetworkImage('${curUser.profileImg}'),
                  backgroundImage: AssetImage('assets/no-profile.png'),
                  radius: 20.0,
                ),
              )
              // )
              ),
          Flexible(
              flex: 10,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  // margin: EdgeInsets.only(top: 7.0, bottom: 7.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                    // color: Colors.blueGrey,
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                            alignment: Alignment.topLeft,
                            child: Row(
                              children: [
                                Text(
                                  curUser.name,
                                  style: TextStyle(
                                      // color: Colors.grey,
                                      fontSize: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .fontSize,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  dateStr + " at " + time,
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .fontSize),
                                )
                              ],
                            )),
                        SizedBox(
                          height: 10,
                        ),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              msg.media!,
                              textAlign: TextAlign.left,
                              style: TextStyle(color: Colors.white),
                            )),
                      ]))),
        ],
      );
    }
    if (msg.media == null && msg.content != null) {
      return Row(
        children: [
          Flexible(
              flex: 1,
              // child: Padding(
              //     padding: EdgeInsets.only(right: 5.0, top: 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: CircleAvatar(
                  backgroundColor: Colors.grey[350],
                  foregroundImage: curUser.profileImg == null
                      ? null
                      : NetworkImage('${curUser.profileImg}'),
                  backgroundImage: AssetImage('assets/no-profile.png'),
                  radius: 20.0,
                ),
              )
              // )
              ),
          Flexible(
              flex: 10,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  // margin: EdgeInsets.only(top: 7.0, bottom: 7.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                    // color: Colors.blueGrey,
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                            alignment: Alignment.topLeft,
                            child: Row(
                              children: [
                                Text(
                                  curUser.name,
                                  style: TextStyle(
                                      // color: Colors.grey,
                                      fontSize: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .fontSize,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  dateStr + " at " + time,
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .fontSize),
                                )
                              ],
                            )),
                        SizedBox(
                          height: 10,
                        ),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              msg.content!,
                              textAlign: TextAlign.left,
                              style: TextStyle(color: Colors.white),
                            )),
                      ]))),
        ],
      );
    }
    return Container();
  }

  _buildMessage(BuildContext context, RoomsMessage msg, bool prevIsSame,
      DateTime? prependDay) {
    var curUser = Provider.of<List<User>>(context, listen: false)
        .where((element) => element.userId == msg.fromUser)
        .toList()[0];
    final time = TimeOfDay.fromDateTime(msg.time).format(context);
    final double msgSpacing = prevIsSame ? 0 : 11;
    late final dateStr;
    if (DateTime.now().day == msg.time.day) {
      dateStr = "Today";
    } else if (DateTime.now().difference(msg.time).inDays == -1) {
      dateStr = "Yesterday";
    } else {
      dateStr =
          "${msg.time.day.toString().padLeft(2, "0")}/${msg.time.month.toString().padLeft(2, "0")}/${msg.time.year.toString().substring(2)}";
    }
    final msgContent = Bubble(
      borderWidth: 0,
      color: Colors.transparent,
      elevation: 0,
      // borderUp: false,
      margin: BubbleEdges.only(top: msgSpacing),
      alignment: Alignment.topLeft,
      // padding: BubbleEdges.all(10),
      child: buildSingleMsg(msg, curUser, dateStr, time),
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

  void _sendMessage({
    required BuildContext context,
    required String channelId,
    String? content,
    Map? media,
    int? replyTo,
  }) {
    if (media != null && media.keys.length == 0) media = null;
    if (content == '') content = null;
    if (media == null && content == null) {
      return;
    }

    Provider.of<MessageExchangeStream>(context, listen: false)
        .sendWSMessage(jsonEncode({
      'type': 'RoomsMessage',
      'roomId': widget.roomId,
      'channelId': channelId,
      'fromUser': Provider.of<UserId>(context, listen: false),
      'content': content,
      'time': DateTime.now().toUtc().toIso8601String(),
      'mediaData': media,
      'replyTo': replyTo,
    }));
    BlocProvider.of<FilePickerCubit>(context, listen: false)
        .updateFilePicker(media: Map(), i: 0);
  }

  Widget _buildMessagesView(List<RoomsMessage> msgs, String channelId) {
    msgs = msgs.where((element) => element.channelId == channelId).toList();
    return Expanded(
        child: Column(
      children: [
        Expanded(
            child: ListView.builder(
                reverse: true,
                padding: EdgeInsets.only(top: 15.0),
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
                      prevIsSame, prependDay);
                }))
      ],
    ));
  }

  Future<bool> onBackPress() {
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return widget.channelId == null
        ? SelectChannelPage()
        : FutureBuilder(
            future: RepositoryProvider.of<AppDb>(context)
                .getRoomMembers(roomID: widget.roomId)
                .get(),
            builder: (BuildContext _,
                AsyncSnapshot<List<User>> roomMembersSnapshot) {
              if (roomMembersSnapshot.hasData) {
                return FutureBuilder(
                    future: RepositoryProvider.of<AppDb>(context)
                        .getRoomChannelChat(
                            roomId: widget.roomId, channelId: widget.channelId!)
                        .get(),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<RoomsMessage>> roomChatsnapshot) {
                      if (roomChatsnapshot.hasData) {
                        return MultiProvider(
                            providers: [
                              Provider<List<User>>(
                                  create: (_) => roomMembersSnapshot.data!),
                              BlocProvider(
                                  lazy: false,
                                  create: (context) {
                                    var cubit = RoomChatCubit(
                                        roomId: widget.roomId,
                                        initialState: roomChatsnapshot.data!);
                                    webSocketSubscription =
                                        Provider.of<MessageExchangeStream>(
                                                context,
                                                listen: false)
                                            .stream
                                            .where((encodedData) {
                                      var data = jsonDecode(encodedData);
                                      return data['roomId'] == widget.roomId;
                                    }).listen((encodedData) {
                                      var data = jsonDecode(encodedData);
                                      cubit.addMessage(
                                          msgId: data['msgId'],
                                          fromUser: data['fromUser'],
                                          roomId: data['roomId'],
                                          channelId: data['channelId'],
                                          time: DateTime.parse(data['time'])
                                              .toLocal(),
                                          content: data['content'] == ''
                                              ? null
                                              : data['content'],
                                          media: data['media'] == ''
                                              ? null
                                              : data['media'],
                                          replyTo: data['replyTo'] == ''
                                              ? null
                                              : data['replyTo']);
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
                              return Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    BlocBuilder<RoomChatCubit,
                                        List<RoomsMessage>>(
                                      builder: (BuildContext context,
                                              List<RoomsMessage> chatstate) =>
                                          _buildMessagesView(
                                              chatstate, widget.channelId!),
                                    ),
                                    MsgBox(
                                      sendMessage: _sendMessage,
                                      channelId: widget.channelId!,
                                    )
                                  ]);
                            }));
                      }
                      return CircularProgressIndicator();
                    });
              } else if (roomMembersSnapshot.hasError) {
                print(roomMembersSnapshot.error);
                return SnackBar(
                    content:
                        Text('Error has occured while reading from local DB'));
              }
              return CircularProgressIndicator();
            });
  }
}
