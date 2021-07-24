import 'dart:io';
import '../../utils/emoji.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MsgBox extends StatefulWidget {
  final Function sendMessage;
  final String? channelId;
  MsgBox({required this.sendMessage, this.channelId});
  @override
  MsgBoxState createState() => new MsgBoxState();
}

class MsgBoxState extends State<MsgBox> {
  final inputController = TextEditingController();
  bool isShowSticker = false;

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
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      // Navigator.pop(context);
      // isShowSticker = true;
    }

    return Future.value(false);
  }

  Widget emojiKeyboard() {

    final emojiList = Emoji.all();
    var i = 0;
    print(emojiList.length);
    return Container(
        padding: EdgeInsets.only(left: 5, right: 5, bottom: 5, top: 5),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height / 3,
        child: GridView.count(
            crossAxisCount: 13,
            children: List.generate(
                emojiList.length,
                (index) => Center(
                      child: InkWell(
                        onTap: () {
                          inputController.text =
                              inputController.text + emojiList[index].char!;
                        },
                        child: Text(
                          emojiList[index].char!,
                          style: TextStyle(fontSize: 25),
                        ),
                      ),
                    ))));
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
                          isShowSticker = !isShowSticker;
                        }),
                        FocusScope.of(context).unfocus()
                      },
                  icon: Icon(Icons.emoji_emotions)),
              Expanded(
                  child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (RawKeyEvent event) {
                        setState(() {
                          isShowSticker = false;
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
                            widget.channelId == ''
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
                            isShowSticker = false;
                          });
                        },
                        onEditingComplete: () {
                          String data = inputController.text;
                          inputController.clear();
                          widget.channelId == ''
                              ? widget.sendMessage(
                                  context: context, content: data.trim())
                              : widget.sendMessage(
                                  context: context,
                                  content: data.trim(),
                                  channelId: widget.channelId);
                          ;
                        },
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Type a message'),
                      ))),
              IconButton(
                  onPressed: () {
                    String data = inputController.text;
                    inputController.clear();
                    widget.channelId == ''
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
          isShowSticker ? emojiKeyboard() : Container(),
        ],
      ),
    );
  }
}
