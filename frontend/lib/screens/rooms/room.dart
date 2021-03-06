import 'dart:convert';
import 'dart:typed_data';
import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:yaroom/blocs/roomMetadata.dart';
import 'package:yaroom/utils/authorizationService.dart';
import 'package:provider/provider.dart';
import 'package:yaroom/blocs/rooms.dart';
import 'package:yaroom/utils/notifiers.dart';
import '../components/msgBox.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/messageExchange.dart';
import '../../utils/types.dart';
import '../../utils/guidePages.dart';
import 'package:http/http.dart' as http;

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
  late var webSocketSubscription;
  List<RoomsMessage> newmsgs = [];
  bool moreload = true;
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

  Future<Widget> _buildSingleMsg(
      RoomsMessage msg, var curUser, var dateStr, var time) async {
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
                    foregroundImage: iconImageWrapper(curUser.userId),
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
    } else {
      var media = await http.get(
          Uri.parse('$BACKEND_URL/v1/media/' + msg.media!),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': "Bearer $accessToken",
          });
      var data = jsonDecode(media.body) as Map;
      print(data);
      if (msg.content == null) {
        var temp = data['name'].split(".");
        // if (['jpg', 'jpeg', 'png'].contains(temp.last)) {
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
                    foregroundImage: iconImageWrapper(curUser.userId),
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
                              child: ['jpg', 'jpeg', 'png'].contains(temp.last)
                                  ? Image.memory(Uint8List.fromList(
                                      data['bytes'].cast<int>()))
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
                                    )),
                        ]))),
          ],
        );
      } else {
        var temp = data['name'].split(".");
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
                    foregroundImage: iconImageWrapper(curUser.userId),
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
                                child: ['jpg', 'jpeg', 'png']
                                        .contains(temp.last)
                                    ? Image.memory(Uint8List.fromList(
                                        data['bytes'].cast<int>()))
                                    : Row(
                                        children: [
                                          Text(data['name']),
                                          IconButton(
                                            icon:
                                                const Icon(Icons.file_download),
                                            tooltip: 'download',
                                            onPressed: () {
                                              savefile(data, context);
                                            },
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ]))),
          ],
        );
      }
    }
  }

  _buildMessage(BuildContext context, RoomsMessage msg, bool prevIsSame,
      DateTime? prependDay) {
    var query = Provider.of<RoomMetadataCubit>(context, listen: false)
        .state
        .data[widget.roomId]!
        .roomMembers
        .where((element) => element.userId == msg.fromUser)
        .toList();
    var curUser = User(name: 'UnknownUser', userId: msg.fromUser);
    if (!query.isEmpty) {
      curUser = query[0];
    }
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
      child: Builder(
        builder: (context) {
          return FutureBuilder(
              future: _buildSingleMsg(msg, curUser, dateStr, time),
              builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                if (snapshot.hasData) {
                  return snapshot.data!;
                }
                return LoadingBar;
              });
        },
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
      'type': 'RoomMessage',
      'roomId': widget.roomId,
      'channelId': channelId,
      'fromUser': Provider.of<UserId>(context, listen: false),
      'content': content,
      'time': DateTime.now().toUtc().toIso8601String(),
      'mediaData': media,
      'replyTo': replyTo,
    }));
    BlocProvider.of<FilePickerCubit>(context, listen: false)
        .updateFilePicker(media: Map(), filesAttached: 0);
  }

  Widget getSelectChannelPage() {
    webSocketSubscription =
        Provider.of<MessageExchangeStream>(context, listen: false)
            .stream
            .where((_) {
      return false;
    }).listen((_) {});
    return SelectChannelPage();
  }

  loadMore(List<RoomsMessage> msgs) async {
    if (msgs.isNotEmpty && moreload) {
      String? accessToken =
          await Provider.of<AuthorizationService>(context, listen: false)
              .getValidAccessToken();
      if (accessToken == null) {
        Navigator.pushNamed(context, '/signin');
      }
      if (widget.channelId != null) {
        var req = await http.get(
            Uri.parse(
                '$BACKEND_URL/v1/getOlderMessages?msgType=RoomMessage&lastMsgId=' +
                    msgs[0].msgId +
                    '&exchangeId=' +
                    widget.roomId +
                    "@" +
                    widget.channelId! +
                    '&limit=15'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': "Bearer $accessToken",
            });
        print("here");
        print("l" + req.body + "l");
        if (req.body != "null" && req.body != "") {
          if (req.body
              .contains(new RegExp("{\"error\"", caseSensitive: false))) {
            return;
          }
          var results = jsonDecode(req.body).cast<Map<String, dynamic>>();
          List<RoomsMessage> temp = [];
          for (int i = 0; i < results.length; i++) {
            RoomsMessage msg = RoomsMessage(
                fromUser: results[i]['fromUser'],
                msgId: results[i]['msgId'],
                roomId: results[i]['roomId'],
                channelId: results[i]['channelId'],
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
  }

  Widget _buildMessagesView(List<RoomsMessage> msgs, String channelId) {
    msgs = msgs.where((element) => element.channelId == channelId).toList();
    if (msgs.length < 15 && moreload) {
      loadMore(msgs);
      msgs.insertAll(0, newmsgs);
    }
    return Expanded(
        child: Column(
      children: [
        Expanded(
            child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels ==
                scrollInfo.metrics.maxScrollExtent) {
              loadMore(msgs);
              // newmsgs.addAll(msgs);
              msgs.insertAll(0, newmsgs);
              // setState(() {
              //   newmsgs:[];
              // });
              return true;
            }
            return false;
          },
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
                DateTime? prependDay =
                    prependDayCond ? msgs[msgs.length - 1 - index].time : null;
                return _buildMessage(context, msgs[msgs.length - 1 - index],
                    prevIsSame, prependDay);
              }),
        ))
      ],
    ));
  }

  Future<bool> onBackPress() {
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomList>(
      builder: (_, RoomList roomList, __) {
        return widget.channelId == null
            ? getSelectChannelPage()
            : BlocBuilder<RoomMetadataCubit, RoomMetadataMap>(
                builder: (BuildContext _, state) {
                if (state.data.containsKey(widget.roomId)) {
                  return FutureBuilder(
                      future: RepositoryProvider.of<AppDb>(context)
                          .getRoomChannelChat(
                              roomId: widget.roomId,
                              channelId: widget.channelId!)
                          .get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<List<RoomsMessage>> roomChatsnapshot) {
                        if (roomChatsnapshot.hasData) {
                          return MultiProvider(
                              providers: [
                                Provider<List<User>>(
                                    create: (_) =>
                                        state.data[widget.roomId]!.roomMembers),
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
                                        if (encodedData == "" ||
                                            encodedData == "null" ||
                                            encodedData == "true" ||
                                            encodedData == "false")
                                          return false;
                                        var data = jsonDecode(encodedData);
                                        if (data.containsKey('error') ||
                                            data.containsKey('active') ||
                                            data.containsKey('update') ||
                                            data.containsKey('friendRequest') ||
                                            data.containsKey('exit')) {
                                          return false;
                                        }
                                        return data['type'] == 'RoomMessage' &&
                                            data['roomId'] == widget.roomId;
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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

                        return LoadingBar;
                      });
                }
                return LoadingBar;
              });
      },
    );
  }
}
