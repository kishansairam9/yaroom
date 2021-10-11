import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/types.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DMsList extends ChangeNotifier {
  List<User> chats = [];
  Future<bool> updateChats(context) async {
    this.chats = await RepositoryProvider.of<AppDb>(context).getFriends().get();
    print(this.chats);
    return Future.value(true);
  }

  Future<bool> triggerRerender() async {
    notifyListeners();
    return Future.value(true);
  }
}

class GroupsList extends ChangeNotifier {
  List<GroupDM> groupData = [];
  Future<bool> getGroupData(context) async {
    this.groupData = await RepositoryProvider.of<AppDb>(context)
        .getGroupsOfUser(userID: Provider.of<UserId>(context, listen: false))
        .get();
    print(this.groupData);
    return Future.value(true);
  }

  Future<bool> removeGroup(context, groupId) async {
    await RepositoryProvider.of<AppDb>(context).removeUserFromGroup(
        groupId: groupId, userId: Provider.of<UserId>(context, listen: false));
    this.groupData.removeWhere((element) => element.groupId == groupId);
    notifyListeners();
    return Future.value(true);
  }

  Future<bool> triggerRerender() async {
    notifyListeners();
    return Future.value(true);
  }
}
