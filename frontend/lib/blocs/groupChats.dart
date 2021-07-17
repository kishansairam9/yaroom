import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/types.dart';

class GroupChatCubit extends Cubit<List<GroupChatMessage>> {
  late String groupId;

  GroupChatCubit(
      {required this.groupId, required List<GroupChatMessage> initialState})
      : super(initialState);

  void addMessage(
      {required String msgId,
      required String fromUser,
      required String groupId,
      required DateTime time,
      String? media,
      String? content,
      String? replyTo}) {
    assert(!(media == null && content == null));
    assert(groupId == this.groupId);
    emit(state +
        [
          GroupChatMessage(
              msgId: msgId,
              groupId: groupId,
              fromUser: fromUser,
              time: time,
              media: media,
              content: content,
              replyTo: replyTo)
        ]);
  }
}
