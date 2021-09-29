import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:yaroom/utils/types.dart';

class MsgBox extends StatefulWidget {
  final Function sendMessage;
  final String? channelId;
  final Function? callIfEmojiClosedAndBackPress;
  MsgBox(
      {required this.sendMessage,
      this.channelId,
      this.callIfEmojiClosedAndBackPress});

  @override
  MsgBoxState createState() => new MsgBoxState();
}

class MsgBoxState extends State<MsgBox> {
  final inputController = TextEditingController();
  bool emojiShowing = false;
  var media = new Map();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  Future<bool> onBackPress() {
    if (emojiShowing) {
      setState(() {
        emojiShowing = false;
      });
    } else if (widget.callIfEmojiClosedAndBackPress != null) {
      widget.callIfEmojiClosedAndBackPress!();
    }
    return Future.value(false);
  }

  _onEmojiSelected(Emoji emoji) {
    inputController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: inputController.text.length));
  }

  _onBackspacePressed() {
    inputController
      ..text = inputController.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: inputController.text.length));
  }

  void _openFileExplorer() async {
    FilePickerResult? _paths =
        await FilePicker.platform.pickFiles(withData: true);
    if (_paths != null) {
      media['name'] = _paths.files.first.name;
      media['bytes'] = _paths.files.first.bytes;

      // Provider.of<FilePickerDetails>(context, listen: false)
      //     .updateState(media, 1);
      BlocProvider.of<FilePickerCubit>(context, listen: false)
          .updateFilePicker(media: media, filesAttached: 1);
    }
    // Provider.of<FilePickerDetails>(context, listen: false).filesAttached = 1;
  }

  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onBackPress,
      child: Column(
        children: [
          // Provider.of<FilePickerDetails>(context, listen: false)
          //             .getFilesAttached() !=
          //         0
          //     ? Text(Provider.of<FilePickerDetails>(context, listen: false)
          //             .getFilesAttached()
          //             .toString() +
          //         " file attached")
          //     : Container(),
          BlocBuilder<FilePickerCubit, FilePickerDetails>(
              builder: (context, state) {
            if (state.filesAttached != 0) {
              return Text(state.filesAttached.toString() + " file attached");
            }
            return Container();
          }),
          Row(
            children: [
              IconButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    // Delay only to prevent render overflow when clicking emoji while keyboard open
                    Future.delayed(
                        Duration(milliseconds: 150),
                        () => setState(() {
                              emojiShowing = !emojiShowing;
                            }));
                  },
                  icon: Icon(Icons.emoji_emotions)),
              Expanded(
                  child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (RawKeyEvent event) {
                        setState(() {
                          emojiShowing = false;
                        });
                        if (kIsWeb ||
                            Platform.isMacOS ||
                            Platform.isLinux ||
                            Platform.isWindows) {
                          // Submit on Enter and new line on Shift + Enter only on desktop devices or Web
                          if (event.isKeyPressed(LogicalKeyboardKey.enter) &&
                              !event.isShiftPressed) {
                            String data = inputController.text;
                            inputController.clear();
                            // Bug fix for stray new line after Pressing Enter
                            Future.delayed(Duration(milliseconds: 100),
                                () => inputController.clear());
                            widget.channelId == null ||
                                    widget.channelId!.isEmpty
                                ? widget.sendMessage(
                                    context: context,
                                    content: data.trim(),
                                    media: BlocProvider.of<FilePickerCubit>(
                                            context,
                                            listen: false)
                                        .state
                                        .media)
                                : widget.sendMessage(
                                    context: context,
                                    content: data.trim(),
                                    channelId: widget.channelId,
                                    media: BlocProvider.of<FilePickerCubit>(
                                            context,
                                            listen: false)
                                        .state
                                        .media);
                          }
                        }
                      },
                      child: TextField(
                        maxLines: null,
                        controller: inputController,
                        textCapitalization: TextCapitalization.sentences,
                        onTap: () {
                          setState(() {
                            emojiShowing = false;
                          });
                        },
                        onEditingComplete: () {
                          String data = inputController.text;
                          inputController.clear();
                          widget.channelId == null || widget.channelId!.isEmpty
                              ? widget.sendMessage(
                                  context: context,
                                  content: data.trim(),
                                  media: BlocProvider.of<FilePickerCubit>(
                                          context,
                                          listen: false)
                                      .state
                                      .media)
                              : widget.sendMessage(
                                  context: context,
                                  content: data.trim(),
                                  channelId: widget.channelId,
                                  media: BlocProvider.of<FilePickerCubit>(
                                          context,
                                          listen: false)
                                      .state
                                      .media);
                        },
                        decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: Icon(Icons.attach_file),
                              onPressed: () {
                                _openFileExplorer();
                              },
                            ),
                            border: OutlineInputBorder(),
                            hintText: 'Type a message'),
                      ))),
              IconButton(
                  onPressed: () {
                    String data = inputController.text;
                    inputController.clear();
                    widget.channelId == null || widget.channelId!.isEmpty
                        ? widget.sendMessage(
                            context: context,
                            content: data.trim(),
                            media: BlocProvider.of<FilePickerCubit>(context,
                                    listen: false)
                                .state
                                .media)
                        : widget.sendMessage(
                            context: context,
                            content: data.trim(),
                            channelId: widget.channelId,
                            media: BlocProvider.of<FilePickerCubit>(context,
                                    listen: false)
                                .state
                                .media);
                    ;
                  },
                  icon: Icon(Icons.send))
            ],
          ),
          Offstage(
              offstage: !emojiShowing,
              child: Theme(
                data: kIsWeb
                    ? ThemeData(fontFamily: 'NotoColorEmojiWeb')
                    : ThemeData(fontFamily: 'NotoColorEmoji'),
                child: SizedBox(
                  height: 300,
                  child: EmojiPicker(
                      onEmojiSelected: (Category category, dynamic emoji) {
                        _onEmojiSelected(emoji);
                      },
                      onBackspacePressed: _onBackspacePressed,
                      config: const Config(
                          columns: kIsWeb ? 20 : 7,
                          emojiSizeMax: 32.0,
                          verticalSpacing: 0,
                          horizontalSpacing: 10,
                          initCategory: Category.RECENT,
                          bgColor: Color(0xFFF2F2F2),
                          indicatorColor: Colors.blue,
                          iconColor: Colors.grey,
                          iconColorSelected: Colors.blue,
                          progressIndicatorColor: Colors.blue,
                          backspaceColor: Colors.blue,
                          showRecentsTab: true,
                          recentsLimit: 28,
                          noRecentsText: 'No Recents',
                          noRecentsStyle:
                              TextStyle(fontSize: 20, color: Colors.black26),
                          categoryIcons: CategoryIcons(),
                          buttonMode: ButtonMode.MATERIAL)),
                ),
              )),
        ],
      ),
    );
  }
}
