import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/types.dart';

class UserChatCubit extends Cubit<List<ChatMessage>> {
  late int otherUser;
  late AppDb db;

  UserChatCubit(
      {required this.otherUser,
      required this.db,
      required List<ChatMessage> initialState})
      : super(initialState);

  void insertTextMessage(
      {required int msgId, required int fromUser, required String content}) {
    this.db.insertTextMessage(
        msgId: msgId,
        fromUser: fromUser,
        toUser: otherUser,
        time: DateTime.now(),
        content: content);
    emit(state +
        [
          ChatMessage(
              msgId: msgId,
              fromUser: fromUser,
              toUser: otherUser,
              time: DateTime.now(),
              content: content)
        ]);
  }

  void insertMediaMessage(
      {required int msgId,
      required int fromUser,
      required String media,
      String? content}) {
    this.db.insertMediaMessage(
        msgId: msgId,
        fromUser: fromUser,
        toUser: otherUser,
        time: DateTime.now(),
        media: media,
        content: content);
    emit(state +
        [
          ChatMessage(
              msgId: msgId,
              fromUser: fromUser,
              toUser: otherUser,
              time: DateTime.now(),
              media: media,
              content: content)
        ]);
  }
}
