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

ImageProvider iconImageWrapper(String? src) {
  String url = "http://localhost:8884/icon";
  if (src != null) {
    url += "?objectid=" + src;
  }
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

class CounterStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> _localFile(String filename) async {
    final path = await _localPath;
    return File('$path/' + filename);
  }

  Future<int> readCounter(String filename) async {
    try {
      final file = await _localFile(filename);

      // Read the file
      final contents = await file.readAsString();

      return int.parse(contents);
    } catch (e) {
      // If encountering an error, return 0
      return 0;
    }
  }

  Future<File> writeCounter(String filename, Uint8List bytes) async {
    final file = await _localFile(filename);

    // Write the file
    return file.writeAsBytes(bytes);
  }
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
  // void updateState(Map<dynamic, dynamic> media, int i) {
  //   this.media = media;
  //   filesAttached = i;
  //   print(filesAttached);
  //   print(media);
  // }

  // Map<dynamic, dynamic> getMedia() {
  //   return media;
  // }

  // int getFilesAttached() {
  //   return filesAttached;
  // }
}

class FilePickerCubit extends Cubit<FilePickerDetails> {
  FilePickerCubit({required FilePickerDetails initialState})
      : super(initialState);

  void updateFilePicker(
      {required Map<dynamic, dynamic> media, required int i}) {
    print(i);
    print(media);
    emit(FilePickerDetails(media: media, filesAttached: i));
  }
}

class GroupChatPageArguments {
  late final String groupId, name;
  late final String? image, description;

  GroupChatPageArguments(
      {required this.groupId,
      required this.name,
      this.image,
      this.description});
}
