export '../moor/db.dart';

typedef UserId = String;
typedef FCMTokenStream = Stream<String>;

class HomePageArguments {
  late final int? index;
  late final String? roomId;
  late final String? roomName;
  late final String? roomIcon;
  late final String? channelId;

  HomePageArguments(
      {this.index, this.roomId, this.roomName, this.channelId, this.roomIcon});
}

class RoomArguments extends HomePageArguments {
  RoomArguments({roomId, roomName, channelId, roomIcon})
      : super(
            index: 0,
            roomId: roomId,
            roomName: roomName,
            channelId: channelId,
            roomIcon: roomIcon);
}

class ChatPageArguments {
  late final String userId, name;
  late final String? image;

  ChatPageArguments({required this.userId, required this.name, this.image});
}

class GroupChatPageArguments {
  late final String groupId, name;
  late final String? image;

  GroupChatPageArguments({required this.groupId, required this.name, this.image});
}
