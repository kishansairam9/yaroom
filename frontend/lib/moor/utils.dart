import 'db.dart';

Future<void> updateDb(AppDb db, Map<dynamic, dynamic> data) async {
  data['time'] = DateTime.parse(data['time']).toLocal();
  if (data['type'] == 'ChatMessage') {
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
        .catchError((e) {
      print("Database insert failed with error $e");
    });
  } else if (data['type'] == 'GroupChatMessage') {
    await db.insertGroupChatMessage(
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
    );
  } else if (data['type'] == 'RoomsMessage') {
    await db
        .insertRoomsChannelMessage(
      msgId: data['msgId'],
      roomId: data['roomId'],
      channelId: data['channelId'],
      fromUser: data['fromUser'],
      time: data['time'],
      content: data['content'] == '' ? null : data['content'],
      media: data['media'] == '' ? null : data['media'],
      replyTo: data['replyTo'] == '' ? null : data['replyTo'],
    )
        .catchError((e) {
      print("Database insert failed with error $e");
    });
  }
}
