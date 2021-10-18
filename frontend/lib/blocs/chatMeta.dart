import 'package:hydrated_bloc/hydrated_bloc.dart';

class ChatMetaState {
  late String userId;
  late Map<String, ChatMeta>? data;
  ChatMetaState({required this.data, required this.userId});

  Map<String, ChatMeta> update(
      String exchangeId, String lastPreview, String sender) {
    Map<String, ChatMeta> statusMap = data!;
    if (!statusMap.containsKey(exchangeId)) {
      statusMap[exchangeId] = ChatMeta();
    }
    statusMap[exchangeId]!.addLatest(lastPreview, sender != userId);
    return statusMap;
  }

  Map<String, ChatMeta> read(String exchangeId) {
    Map<String, ChatMeta> statusMap = data!;
    if (!statusMap.containsKey(exchangeId)) {
      statusMap[exchangeId] = ChatMeta();
    }
    statusMap[exchangeId]!.read();
    return statusMap;
  }

  String getLastMsgPreview(String exchangeId) {
    if (!data!.containsKey(exchangeId)) {
      return "";
    }
    return data![exchangeId]!.previewLastMsg;
  }

  int getUnread(String exchangeId) {
    if (!data!.containsKey(exchangeId)) {
      return 0;
    }
    return data![exchangeId]!.unread;
  }
}

class ChatMetaCubit extends HydratedCubit<ChatMetaState> {
  ChatMetaCubit() : super(ChatMetaState(data: Map(), userId: ''));

  @override
  ChatMetaState? fromJson(Map<String, dynamic> json) {
    String uid = "";
    Map<String, ChatMeta> clean = json.map((k, v) {
      if (k == 'userId') {
        uid = v['userId'];
        return MapEntry(k, ChatMeta());
      }
      return MapEntry(k, ChatMeta().fromJson(v));
    });
    return ChatMetaState(data: clean, userId: uid);
  }

  @override
  Map<String, dynamic>? toJson(ChatMetaState state) {
    var dataMap = state.data!.map((k, v) => MapEntry(k, v.toJson()));
    dataMap['userId'] = {'userId': state.userId};
    return dataMap;
  }

  update(String exchangeId, String lastPreview, String sender) {
    emit(ChatMetaState(
        data: state.update(exchangeId, lastPreview, sender),
        userId: state.userId));
  }

  read(String exchangeId) {
    emit(ChatMetaState(data: state.read(exchangeId), userId: state.userId));
  }

  setUser(String uid) {
    print("Set userId in ChatMetaState as $uid");
    emit(ChatMetaState(data: Map(), userId: uid));
  }
}

class ChatMeta {
  late String previewLastMsg;
  late int unread;
  ChatMeta({this.previewLastMsg = "", this.unread = 0});

  void addLatest(String msg, bool isNotSender) {
    previewLastMsg = msg;
    if (isNotSender)
      unread += 1;
    else {
      previewLastMsg = "You: " + previewLastMsg;
      unread = 0;
    }
  }

  void read() {
    unread = 0;
  }

  ChatMeta fromJson(Map<String, dynamic> json) {
    return ChatMeta(
        previewLastMsg: json["previewLastMsg"], unread: json["unread"]);
  }

  Map<String, dynamic>? toJson() {
    return {"previewLastMsg": previewLastMsg, "unread": unread};
  }
}
