import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/types.dart';

class GroupMetadata {
  late String groupId;
  late String name;
  late String description;
  late List<User> groupMembers;
  GroupMetadata(
      {required this.groupId,
      required this.groupMembers,
      required this.name,
      this.description = ""});
}

class GroupMetadataMap {
  late Map<String, GroupMetadata> data;
  GroupMetadataMap(this.data);

  Map<String, GroupMetadata> update(GroupMetadata change) {
    Map<String, GroupMetadata> statusMap = data;
    statusMap[change.groupId] = change;
    return statusMap;
  }

  Map<String, GroupMetadata> delete(String groupId) {
    Map<String, GroupMetadata> statusMap = data;
    statusMap.remove(groupId);
    return statusMap;
  }
}

class GroupMetadataCubit extends Cubit<GroupMetadataMap> {
  GroupMetadataCubit({required GroupMetadataMap initialState})
      : super(initialState);

  void update(GroupMetadata data) {
    emit(GroupMetadataMap(state.update(data)));
  }

  void delete(String groupId) {
    emit(GroupMetadataMap(state.delete(groupId)));
  }
}
