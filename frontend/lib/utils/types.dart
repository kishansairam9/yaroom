export '../moor/db.dart';

typedef UserId = String;

class RoomArguments {
  final String roomId;
  final String roomName;

  RoomArguments(this.roomId, this.roomName);
}