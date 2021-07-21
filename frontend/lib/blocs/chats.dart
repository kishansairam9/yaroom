import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/types.dart';

class UserChatCubit extends Cubit<List<ChatMessage>> {
  late String otherUser;

  UserChatCubit(
      {required this.otherUser, required List<ChatMessage> initialState})
      : super(initialState);

  void addMessage(
      {required String msgId,
      required String fromUser,
      required DateTime time,
      required String toUser,
      String? media,
      String? content,
      String? replyTo}) {
    assert(!(media == null && content == null));
    assert(fromUser == otherUser || toUser == otherUser);
    emit(state +
        [
          ChatMessage(
              msgId: msgId,
              fromUser: fromUser,
              toUser: toUser,
              time: time,
              media: media,
              content: content,
              replyTo: replyTo)
        ]);
  }
}
