import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/messageExchange.dart';
import 'dart:convert';
import '../../utils/types.dart';

class ChatMetaState {
  late String userId;
  late Map<String, ChatMeta> data;
  late Map<String, String> lastMsgRead;
  ChatMetaState(
      {required this.data, required this.userId, required this.lastMsgRead});

  dynamic update(
      String exchangeId, String msgId, String lastPreview, String sender) {
    Map<String, ChatMeta> statusMap = data;
    Map<String, String> msgMap = lastMsgRead;
    if (!statusMap.containsKey(exchangeId)) {
      statusMap[exchangeId] = ChatMeta();
    }
    if (sender == userId &&
        (!msgMap.containsKey(exchangeId) ||
            msgMap[exchangeId]!.compareTo(msgId) < 0)) {
      msgMap[exchangeId] = msgId;
    }
    var cmp = !msgMap.containsKey(exchangeId) ? "" : msgMap[exchangeId]!;
    print(
        "Incoming msgId $msgId, stored last read ${msgMap[exchangeId]} compare with $cmp = ${msgId.compareTo(cmp)}");
    bool unread = msgId.compareTo(cmp) > 0;
    statusMap[exchangeId]!
        .addLatest(lastPreview, sender != userId, isUnread: unread);
    return [statusMap, msgMap];
  }

  dynamic read(String exchangeId, String lastMsgId, BuildContext context) {
    Map<String, ChatMeta> statusMap = data;
    Map<String, String> msgMap = lastMsgRead;
    if (!statusMap.containsKey(exchangeId)) {
      statusMap[exchangeId] = ChatMeta();
    }
    msgMap[exchangeId] = lastMsgId;
    statusMap[exchangeId]!.read();
    Provider.of<MessageExchangeStream>(context, listen: false)
        .sendWSMessage(jsonEncode({
      'type': 'LastRead',
      'userId': Provider.of<UserId>(context, listen: false),
      'fromUser': Provider.of<UserId>(context, listen: false),
      'exchangeId': exchangeId,
      'lastRead': lastMsgId
    }));
    return [statusMap, msgMap];
  }

  String getLastMsgPreview(String exchangeId) {
    if (!data.containsKey(exchangeId)) {
      return "";
    }
    return data[exchangeId]!.previewLastMsg;
  }

  int getUnread(String exchangeId) {
    if (!data.containsKey(exchangeId)) {
      return 0;
    }
    return data[exchangeId]!.unread;
  }
}

class ChatMetaCubit extends HydratedCubit<ChatMetaState> {
  ChatMetaCubit()
      : super(ChatMetaState(
            data: Map(), lastMsgRead: Map<String, String>(), userId: ''));

  @override
  ChatMetaState? fromJson(Map<String, dynamic> json) {
    String uid = json['userId'];
    Map<String, ChatMeta> dataMap = Map();
    json['data'].forEach((k, v) => dataMap[k] = ChatMeta().fromJson(v));
    Map<String, String> lastMsgRead = Map();
    json['lastMsg'].forEach((k, v) => lastMsgRead[k] = v);
    return ChatMetaState(data: dataMap, lastMsgRead: lastMsgRead, userId: uid);
  }

  @override
  Map<String, dynamic>? toJson(ChatMetaState state) {
    var dataMap = state.data.map((k, v) => MapEntry(k, v.toJson()));
    Map<String, dynamic> stateMap = {};
    stateMap['data'] = dataMap;
    stateMap['lastMsg'] = state.lastMsgRead;
    stateMap['userId'] = state.userId;
    return stateMap;
  }

  update(String exchangeId, String msgId, String preview, String sender) {
    dynamic newState = state.update(exchangeId, msgId, preview, sender);
    emit(ChatMetaState(
        data: newState[0], lastMsgRead: newState[1], userId: state.userId));
  }

  read(String exchangeId, String lastMsgId, BuildContext context) {
    dynamic newState = state.read(exchangeId, lastMsgId, context);
    emit(ChatMetaState(
        data: newState[0], lastMsgRead: newState[1], userId: state.userId));
  }

  setUser(String uid, Map<String, String> lastMsgRead) {
    print("Set userId in ChatMetaState as $uid");
    emit(ChatMetaState(data: Map(), lastMsgRead: lastMsgRead, userId: uid));
  }
}

class ChatMeta {
  late String previewLastMsg;
  late int unread;
  ChatMeta({this.previewLastMsg = "", this.unread = 0});

  void addLatest(String msg, bool isNotSender, {bool isUnread = false}) {
    previewLastMsg = msg;
    if (isUnread)
      unread += 1;
    else {
      unread = 0;
    }
    if (!isNotSender) {
      previewLastMsg = "You: " + previewLastMsg;
    }
  }

  void read() {
    unread = 0;
  }

  ChatMeta fromJson(Map<dynamic, dynamic> json) {
    return ChatMeta(
        previewLastMsg: json["previewLastMsg"], unread: json["unread"]);
  }

  Map<String, dynamic>? toJson() {
    return {"previewLastMsg": previewLastMsg, "unread": unread};
  }
}
