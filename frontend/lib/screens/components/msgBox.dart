import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class MsgBox extends StatefulWidget {
  final Function sendMessage;
  final String? channelId;
  MsgBox({required this.sendMessage, this.channelId});

  @override
  MsgBoxState createState() => new MsgBoxState();
}

class MsgBoxState extends State<MsgBox> {
  final inputController = TextEditingController();
  bool emojiShowing = false;

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

  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onBackPress,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: () => {
                        setState(() {
                          emojiShowing = !emojiShowing;
                        }),
                        FocusScope.of(context).unfocus()
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
                                    context: context, content: data.trim())
                                : widget.sendMessage(
                                    context: context,
                                    content: data.trim(),
                                    channelId: widget.channelId);
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
                                  context: context, content: data.trim())
                              : widget.sendMessage(
                                  context: context,
                                  content: data.trim(),
                                  channelId: widget.channelId);
                        },
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Type a message'),
                      ))),
              IconButton(
                  onPressed: () {
                    String data = inputController.text;
                    inputController.clear();
                    widget.channelId == null || widget.channelId!.isEmpty
                        ? widget.sendMessage(
                            context: context, content: data.trim())
                        : widget.sendMessage(
                            context: context,
                            content: data.trim(),
                            channelId: widget.channelId);
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
