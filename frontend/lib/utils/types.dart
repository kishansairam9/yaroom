export '../moor/db.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moor/moor.dart';
import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:bloc/bloc.dart';

typedef UserId = String;
typedef FCMTokenStream = Stream<String>;

enum ConnectivityFlags { wsActive, wsRetrying, closed }

ImageProvider iconImageWrapper(String? src) {
  String url = "http://localhost:8884/icon";
  if (src != null) {
    url += "/" + src;
  }
  url += "?time=" + DateTime.now().toString();
  // print("Sent image request to $url");
  return NetworkImage(url);
}

class HomePageArguments {
  late final int? index;
  late final String? roomId;
  late final String? roomName;
  late final String? channelId;

  HomePageArguments({this.index, this.roomId, this.roomName, this.channelId});
}

class MediaStore {
  static const _channel = MethodChannel('flutter_media_store');

  Future<void> addItem({required File file, required String name}) async {
    await _channel.invokeMethod('addItem', {'path': file.path, 'name': name});
  }
}

Future<void> saveFileToMediaStore(File file, String name) async {
  final mediaStore = MediaStore();
  await mediaStore.addItem(file: file, name: name);
}

class RoomArguments extends HomePageArguments {
  RoomArguments({roomId, roomName, channelId})
      : super(
            index: 0, roomId: roomId, roomName: roomName, channelId: channelId);
}

class ChatPageArguments {
  late final String userId, name;

  ChatPageArguments({required this.userId, required this.name});
}

class FilePickerDetails {
  int filesAttached;
  Map<dynamic, dynamic> media;
  FilePickerDetails({required this.media, required this.filesAttached});
}

class FilePickerCubit extends Cubit<FilePickerDetails> {
  FilePickerCubit({required FilePickerDetails initialState})
      : super(initialState);

  void updateFilePicker(
      {required Map<dynamic, dynamic> media, required int filesAttached}) {
    emit(FilePickerDetails(media: media, filesAttached: filesAttached));
  }
}

class IconPickerCubit extends Cubit<FilePickerDetails> {
  IconPickerCubit({required FilePickerDetails initialState})
      : super(initialState);

  void updateFilePicker(
      {required Map<dynamic, dynamic> media, required int filesAttached}) {
    emit(FilePickerDetails(media: media, filesAttached: filesAttached));
  }
}

class GroupChatPageArguments {
  late final String groupId;

  GroupChatPageArguments({required this.groupId});
}

enum FriendRequestType { placeholder, pending, friend, reject, removeFriend }
