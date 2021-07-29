import 'package:faker/faker.dart';
import 'dart:math';
import 'utils/types.dart';

Function counterClosure(int start) {
  return () {
    start += 1;
    return start.toString();
  };
}

dynamic getUserId = counterClosure(13);
dynamic getMsgId = counterClosure(44000);
dynamic getGroupId = counterClosure(100000);
dynamic getRoomId = counterClosure(5000000);

dynamic getImage() => faker.image.image(
    width: 150, height: 150, keywords: ['people', 'nature'], random: true);

dynamic getGroupImage() => faker.image.image(
    width: 150, height: 150, keywords: ['office', 'corporate'], random: true);

dynamic getName() => faker.person.name();
dynamic getCompanyName() => faker.company.name();

final _chars =
    'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890 ';
Random _rnd = Random();

String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

dynamic getAbout() => getRandomString(Random().nextInt(70));

int getRandomInt(int minm, int maxm) => Random().nextInt(maxm) + minm;

dynamic getExchange() {
  final random = Random().nextInt(20) + 1;
  final sender = [];
  final msgs = [];
  for (int i = 0; i < random; i++) {
    sender.add(Random().nextInt(2));
    msgs.add(getRandomString(Random().nextInt(100) + 1));
  }
  return [msgs, sender];
}

void fakeInsert(AppDb db, UserId userId) {
  var others = [];
  // Generate fake data
  db.addUser(
      userId: userId,
      name: getName(),
      about: getAbout(),
      profileImg: getImage());
  for (var i = 0; i < 30; i++) {
    String uid = getUserId();
    others.add(uid);
    db.addUser(
        userId: uid,
        name: getName(),
        about: getAbout(),
        profileImg: getImage());
    if (Random().nextBool()) {
      db.addNewFriend(
          userId_1: userId, userId_2: uid, status: getRandomInt(1, 3));
    }
    var exchange = getExchange();
    for (var j = 0; j < exchange[0].length; j++) {
      late String fromId, toId;
      if (exchange[1][j] == 0) {
        fromId = userId;
        toId = uid;
      } else {
        fromId = uid;
        toId = userId;
      }
      db.insertMessage(
          msgId: getMsgId(),
          fromUser: fromId,
          toUser: toId,
          time: DateTime.fromMillisecondsSinceEpoch(j * 1000 * 62),
          content: exchange[0][j]);
    }
  }
  for (var i = 0; i < 30; i++) {
    String gid = getGroupId();
    db.createGroup(
        groupId: gid,
        name: getCompanyName(),
        description: getAbout(),
        groupIcon: getGroupImage());
    int groupSize = getRandomInt(5, 20);
    var groupMembers = new List.generate(
        groupSize, (_) => others[Random().nextInt(others.length)]);
    groupMembers.add(userId);
    groupMembers = groupMembers.toSet().toList();
    groupSize = groupMembers.length;
    for (var j = 0; j < groupSize; j++) {
      db.addUserToGroup(groupId: gid, userId: groupMembers[j]);
    }
    var exchange = getExchange();
    for (var j = 0; j < exchange[0].length; j++) {
      db.insertGroupChatMessage(
          msgId: getMsgId(),
          groupId: gid,
          fromUser: groupMembers[Random().nextInt(groupMembers.length)],
          time: DateTime.fromMillisecondsSinceEpoch(j * 1000 * 62),
          content: exchange[0][j]);
    }
  }

  for (var i = 0; i < 15; i++) {
    String rid = getRoomId();
    db.createRoom(
        roomId: rid,
        name: getCompanyName(),
        description: getAbout(),
        roomIcon: getGroupImage());
    int roomSize = getRandomInt(5, 20);
    var roomMembers = new List.generate(
        roomSize, (_) => others[Random().nextInt(others.length)]);
    roomMembers.add(userId);
    roomMembers = roomMembers.toSet().toList();
    roomSize = roomMembers.length;
    for (var j = 0; j < roomSize; j++) {
      db.addUserToRoom(roomsId: rid, userId: roomMembers[j]);
    }
    int randomNo = Random().nextInt(10) + 1;
    for (var j = 0; j < randomNo; j++) {
      db.addChannelsToRoom(
          roomId: rid,
          channelId: j.toString(),
          channelName: getRandomString(5));
      var exchange = getExchange();
      for (var k = 0; k < exchange[0].length; k++) {
        db.insertRoomsChannelMessage(
            msgId: getMsgId(),
            roomId: rid,
            channelId: j.toString(),
            fromUser: roomMembers[Random().nextInt(roomMembers.length)],
            time: DateTime.fromMicrosecondsSinceEpoch(j * 1000 * 62),
            content: exchange[0][k]);
      }
    }
  }
}
