import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/types.dart';

class RoomMetadata {
  late String roomId;
  late String name;
  late String description;
  late List<User> roomMembers;
  late Map<String, String> roomChannels;

  RoomMetadata(
      {required this.roomId,
      required this.roomMembers,
      required this.name,
      required this.roomChannels,
      this.description = ""});
}

class RoomMetadataMap {
  late Map<String, RoomMetadata> data;
  RoomMetadataMap(this.data);

  Map<String, RoomMetadata> update(RoomMetadata change) {
    Map<String, RoomMetadata> statusMap = data;
    statusMap[change.roomId] = change;
    return statusMap;
  }

  Map<String, RoomMetadata> delete(String roomId) {
    Map<String, RoomMetadata> statusMap = data;
    statusMap.remove(roomId);
    return statusMap;
  }
}

class RoomMetadataCubit extends Cubit<RoomMetadataMap> {
  RoomMetadataCubit({required RoomMetadataMap initialState})
      : super(initialState);

  void reset() {
    emit(RoomMetadataMap(Map()));
  }

  void update(RoomMetadata data) {
    emit(RoomMetadataMap(state.update(data)));
  }

  void delete(String roomId) {
    emit(RoomMetadataMap(state.delete(roomId)));
  }
}
