import 'dart:math';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'db.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/authorizationService.dart';
import '../blocs/chatMeta.dart';

Future<void> updateDb(
    AppDb db, Map<dynamic, dynamic> data, ChatMetaCubit chatMeta) async {
  data['time'] = DateTime.parse(data['time']).toLocal();
  if (data['type'] == 'ChatMessage') {
    print(data);
    var ids = <String>[data['fromUser'], data['toUser']];
    ids.sort();
    String exchangeId = ids[0] + ":" + ids[1];
    print("exchange id $exchangeId");
    await db
        .insertMessage(
      msgId: data['msgId'],
      toUser: data['toUser'],
      fromUser: data['fromUser'],
      time: data['time'],
      content: !data.containsKey('content') || data['content'] == ''
          ? null
          : data['content'],
      media: !data.containsKey('media') || data['media'] == ''
          ? null
          : data['media'],
      replyTo: !data.containsKey('replyTo') || data['replyTo'] == ''
          ? null
          : data['replyTo'],
    )
        .whenComplete(() {
      chatMeta.update(
          exchangeId,
          !data.containsKey('content') || data['content'] == ''
              ? 'Media'
              : data['content']
                  .toString()
                  .substring(0, min(30, data['content'].length)),
          data['fromUser']);
    }).catchError((e) {
      print("Database insert failed with error $e");
      return 0;
    });
  } else if (data['type'] == 'GroupMessage') {
    await db
        .insertGroupChatMessage(
      msgId: data['msgId'],
      groupId: data['groupId'],
      fromUser: data['fromUser'],
      time: data['time'],
      content: !data.containsKey('content') || data['content'] == ''
          ? null
          : data['content'],
      media: !data.containsKey('media') || data['media'] == ''
          ? null
          : data['media'],
      replyTo: !data.containsKey('replyTo') || data['replyTo'] == ''
          ? null
          : data['replyTo'],
    )
        .whenComplete(() {
      chatMeta.update(
          data['groupId'],
          !data.containsKey('content') || data['content'] == ''
              ? 'Media'
              : data['content']
                  .substring(0, min(data['content'].toString().length, 30)),
          data['fromUser']);
    }).catchError((e) {
      print("Database insert failed with error $e");
      return 0;
    });
  } else if (data['type'] == 'RoomsMessage') {
    await db
        .insertRoomsChannelMessage(
      msgId: data['msgId'],
      roomId: data['roomId'],
      channelId: data['channelId'],
      fromUser: data['fromUser'],
      time: data['time'],
      content: !data.containsKey('content') || data['content'] == ''
          ? null
          : data['content'],
      media: !data.containsKey('media') || data['media'] == ''
          ? null
          : data['media'],
      replyTo: !data.containsKey('replyTo') || data['replyTo'] == ''
          ? null
          : data['replyTo'],
    )
        .whenComplete(() {
      chatMeta.update(
          data['roomId'] + ":" + data['channelId'],
          !data.containsKey('content') || data['content'] == ''
              ? 'Media'
              : data['content']
                  .substring(0, min(data['content'].toString().length, 30)),
          data['fromUser']);
    }).catchError((e) {
      print("Database insert failed with error $e");
      return 0;
    });
  } else {
    print("Got unknown data type $data");
  }
}

Future<bool> delMsg(BuildContext context, User user) async {
  var oldMsg = await RepositoryProvider.of<AppDb>(context)
      .getUserMsgsToDelete(userId: user.userId, count: 10)
      .get();
  for (int i = 0; i < oldMsg.length; i++) {
    await RepositoryProvider.of<AppDb>(context)
        .deleteMsg(msgId: oldMsg[i].msgId);
  }
  return Future.value(true);
}

Future<bool> delOldMsg(BuildContext context, User user) async {
  var oldMsgCount = await RepositoryProvider.of<AppDb>(context)
      .getUserMsgCount(userId: user.userId)
      .get();
  if (oldMsgCount[0] > 10) {
    delMsg(context, user);
  }
  return Future.value(true);
}

Future<bool> cleanFrontendDB(BuildContext context) async {
  final userid = await Provider.of<AuthorizationService>(context, listen: false)
      .getUserId();
  var oldUsers = await RepositoryProvider.of<AppDb>(context)
      .getAllOtherUsers(userId: userid)
      .get();
  for (int i = 0; i < oldUsers.length; i++) {
    await delOldMsg(context, oldUsers[i]);
  }
  return Future.value(true);
}
