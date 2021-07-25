import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../utils/types.dart';

class RoomDetails {
  late String roomId;
  late String roomName;

  RoomDetails({required this.roomId, required this.roomName});

  Map<String, String> toMap() {
    return {"roomId": roomId, "roomName": roomName};
  }
}

class RoomsState {
  Map<String, String> lastOpened = {};
  RoomDetails? lastActive;

  RoomsState({Map<String, String>? lastOpened, this.lastActive}) {
    lastOpened?.forEach((key, value) {
      this.lastOpened[key] = value;
    });
  }
}

class RoomsCubit extends HydratedCubit<RoomsState> {
  RoomsCubit() : super(RoomsState(lastOpened: Map<String, String>()));

  @override
  RoomsState? fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> raw = json["lastOpened"];
    Map<String, String> clean = raw.map((k, v) => MapEntry(k, v.toString()));
    if (!json.containsKey("lastActive")) {
      return RoomsState(lastOpened: clean);
    }
    return RoomsState(
        lastOpened: clean,
        lastActive: RoomDetails(
            roomId: json["lastActive"]["roomId"],
            roomName: json["lastActive"]["roomName"]));
  }

  @override
  Map<String, dynamic>? toJson(RoomsState state) {
    if (state.lastActive == null) {
      return {"lastOpened": state.lastOpened.cast()};
    }
    return {
      "lastActive": state.lastActive!.toMap(),
      "lastOpened": state.lastOpened.cast()
    };
  }

  void updateLastActive(RoomDetails room) {
    RoomsState newState =
        RoomsState(lastActive: room, lastOpened: state.lastOpened);
    emit(newState);
  }

  void updateDefaultChannel(String roomId, String channelId) {
    state.lastOpened[roomId] = channelId;
    emit(
        RoomsState(lastActive: state.lastActive, lastOpened: state.lastOpened));
  }
}

class RoomChatCubit extends Cubit<List<RoomsMessage>> {
  late String roomId;

  RoomChatCubit(
      {required this.roomId, required List<RoomsMessage> initialState})
      : super(initialState);

  void addMessage(
      {required String msgId,
      required String fromUser,
      required String roomId,
      required String channelId,
      required DateTime time,
      String? media,
      String? content,
      String? replyTo}) {
    assert(!(media == null && content == null));
    assert(roomId == this.roomId);
    emit(state +
        [
          RoomsMessage(
              msgId: msgId,
              roomId: roomId,
              channelId: channelId,
              fromUser: fromUser,
              time: time,
              content: content,
              media: media,
              replyTo: replyTo)
        ]);
  }
}
