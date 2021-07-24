import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../utils/types.dart';

class RoomsCubit extends HydratedCubit<Map<String, String>> {
  RoomsCubit() : super(Map<String, String>());

  @override
  Map<String, String>? fromJson(Map<String, dynamic> json) {
    return json.cast();
  }

  @override
  Map<String, dynamic>? toJson(Map<String, String> state) {
    return state;
  }

  void updateDefaultChannel(String roomId, String channelId) {
    Map<String, String> newState = Map.from(state);
    newState[roomId] = channelId;
    emit(newState);
  }
}

class RoomChatCubit extends Cubit<List<RoomsMessage>> {
  late String roomId;

  RoomChatCubit(
      {required this.roomId,
      required List<RoomsMessage> initialState})
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
