import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/types.dart';

class FriendRequestData {
  late String userId;
  late String name;
  late String about;
  late int status;
  FriendRequestData(
      {required this.userId,
      required this.status,
      required this.name,
      this.about = ""});
}

class FriendRequestDataMap {
  late Map<String, FriendRequestData> data;
  FriendRequestDataMap(this.data);

  Map<String, FriendRequestData> update(FriendRequestData change) {
    Map<String, FriendRequestData> statusMap = data;
    statusMap[change.userId] = change;
    return statusMap;
  }

  Map<String, FriendRequestData> delete(String userId) {
    Map<String, FriendRequestData> statusMap = data;
    statusMap.remove(userId);
    return statusMap;
  }
}

class FriendRequestCubit extends Cubit<FriendRequestDataMap> {
  FriendRequestCubit({required FriendRequestDataMap initialState})
      : super(initialState);

  void update(FriendRequestData data) {
    emit(FriendRequestDataMap(state.update(data)));
  }

  void delete(String userId) {
    emit(FriendRequestDataMap(state.delete(userId)));
  }
}
