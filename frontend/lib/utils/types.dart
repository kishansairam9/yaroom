export '../moor/db.dart';

import 'package:bloc/bloc.dart';

typedef UserId = String;
typedef FCMTokenStream = Stream<String>;

class HomePageArguments {
  late final int? index;
  late final String? roomId;
  late final String? roomName;
  late final String? roomIcon;
  late final String? channelId;

  HomePageArguments(
      {this.index, this.roomId, this.roomName, this.channelId, this.roomIcon});
}

class RoomArguments extends HomePageArguments {
  RoomArguments({roomId, roomName, channelId, roomIcon})
      : super(
            index: 0,
            roomId: roomId,
            roomName: roomName,
            channelId: channelId,
            roomIcon: roomIcon);
}

class ChatPageArguments {
  late final String userId, name;
  late final String? image;

  ChatPageArguments({required this.userId, required this.name, this.image});
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
