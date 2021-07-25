export '../moor/db.dart';

typedef UserId = String;

class HomePageArguments {
  late final int? index;
  late final String? roomId;
  late final String? roomName;
  late final String? roomIcon;
  late final String? channelId;

  HomePageArguments(
      {this.index, this.roomId, this.roomName, this.channelId, this.roomIcon});
}

class ChatPageArguments {
  late final String userId, name;
  late final String? image;

  ChatPageArguments({required this.userId, required this.name, this.image});
}
