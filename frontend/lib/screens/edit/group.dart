import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaroom/utils/backendRequests.dart';
import '../../utils/types.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:async';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../utils/authorizationService.dart';
import '../../utils/notifiers.dart';
import 'package:http/http.dart' as http;
import '../../blocs/groupMetadata.dart';

class CreateGroup extends StatefulWidget {
  final data;
  CreateGroup(this.data);

  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  final _formKey = GlobalKey<FormState>();
  var media = new Map();
  bool errOnUpload = false;
  StreamController<bool> updateImage = StreamController();

  @override
  void initState() {
    updateImage.add(true);
    super.initState();
  }

  @override
  void dispose() {
    updateImage.close();
    super.dispose();
  }

  Future<void> _openFileExplorer() async {
    FilePickerResult? _paths = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: false, withData: false);
    if (_paths != null) {
      media['iconId'] = this.widget.data["groupId"];
      File? croppedFile = await ImageCropper.cropImage(
          sourcePath: _paths.files.first.path!,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 94,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
          androidUiSettings: AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true),
          iosUiSettings: IOSUiSettings(
            minimumAspectRatio: 1.0,
          ));
      media['jpegBytes'] = croppedFile!.readAsBytesSync();

      BlocProvider.of<FilePickerCubit>(context, listen: false)
          .updateFilePicker(media: media, filesAttached: 1);
    }
  }

  _addMembers() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext c) {
          return BlocBuilder<GroupMetadataCubit, GroupMetadataMap>(
            builder: (context, state) {
              return FutureBuilder(
                  future: RepositoryProvider.of<AppDb>(context)
                      .getFriendRequests()
                      .get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<GetFriendRequestsResult>> snapshot) {
                    if (snapshot.hasData) {
                      var checklist = [];
                      for (var e in snapshot.data!) {
                        if (!state
                            .data[this.widget.data["groupId"]]!.groupMembers
                            .contains(e.userId)) {
                          checklist.add(CheckBox(title: e.name, id: e.userId));
                        }
                      }
                      return Scaffold(
                        appBar: AppBar(
                          leading: Builder(
                              builder: (context) => IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(Icons.arrow_back))),
                          title: Text("Add more people!"),
                          actions: [
                            TextButton(
                                onPressed: () async {
                                  await editGroup(
                                      jsonEncode(<String, dynamic>{
                                        "groupId": this.widget.data["groupId"],
                                        "name": state
                                            .data[this.widget.data["groupId"]]!
                                            .name,
                                        "description": state
                                            .data[this.widget.data["groupId"]]!
                                            .description,
                                        "groupMembers": checklist
                                            .map((e) => (e.value) ? e.id : null)
                                            .toList()
                                      }),
                                      context);
                                  for (var user in checklist) {
                                    await RepositoryProvider.of<AppDb>(context,
                                            listen: false)
                                        .addUserToGroup(
                                            groupId:
                                                this.widget.data["groupId"],
                                            userId: user.id);
                                  }
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  "ADD",
                                  style: TextStyle(color: Colors.white),
                                ))
                          ],
                        ),
                        body: checklist.length == 0
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                    "All your friends are added to the group!"),
                              )
                            : ListView(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                children: [...checklist],
                              ),
                      );
                    } else if (snapshot.hasError) {
                      print(snapshot.error);
                      return SnackBar(
                          content: Text(
                              'Error has occured while reading from local DB'));
                    }
                    return Container();
                  });
            },
          );
        });
  }

  Widget _createForm(String groupId, String name, String description) {
    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: name,
              decoration: const InputDecoration(
                  icon: Icon(Icons.person_add), labelText: 'Enter Group Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter group name';
                } else {
                  name = value;
                }
                return null;
              },
            ),
            TextFormField(
              initialValue: description,
              decoration: const InputDecoration(
                  icon: Icon(Icons.text_snippet),
                  labelText: 'Enter Group Description'),
              validator: (value) {
                if (value == null) {
                  return 'Please enter description';
                } else {
                  description = value;
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Processing Data')),
                    );
                    var res = await editGroup(
                        jsonEncode(<String, dynamic>{
                          "groupId": groupId,
                          "name": name,
                          "description": description,
                          "groupMembers": [
                            Provider.of<UserId>(context, listen: false)
                          ]
                        }),
                        context);
                    if (res == null) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Group Create Failed, try again!')),
                      );
                      return;
                    }
                    var group = jsonDecode(res);
                    groupId = group["groupId"];
                    ScaffoldMessenger.of(context).clearSnackBars();
                    await Navigator.pushReplacementNamed(context, '/groupchat',
                        arguments: GroupChatPageArguments(
                          groupId: groupId,
                        ));
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Builder(
              builder: (context) => IconButton(
                  onPressed: () async {
                    if (this.widget.data["groupId"] == "")
                      Navigator.pop(context);
                    else {
                      await Navigator.pushReplacementNamed(
                          context, '/groupchat',
                          arguments: GroupChatPageArguments(
                            groupId: this.widget.data["groupId"],
                          ));
                    }
                  },
                  icon: Icon(Icons.arrow_back))),
          title: Text(this.widget.data["groupId"] == ""
              ? "Create Group"
              : "Group Settings"),
          actions: [
            IconButton(
                onPressed: () => _addMembers(), icon: Icon(Icons.person_add))
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 50,
              ),
              errOnUpload
                  ? SnackBar(
                      content: Text('Error occured while uploading retry!'))
                  : Container(),
              StreamBuilder(
                  stream: updateImage.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image(
                          height: 300,
                          width: 300,
                          image: iconImageWrapper(this.widget.data["groupId"]));
                    }
                    return CircularProgressIndicator();
                  }),
              Container(
                child: ElevatedButton(
                  child: Text("Update Icon"),
                  onPressed: () async {
                    await _openFileExplorer();
                    String encData = jsonEncode(
                        BlocProvider.of<FilePickerCubit>(context, listen: false)
                            .state
                            .media);
                    final String? accessToken =
                        await Provider.of<AuthorizationService>(context,
                                listen: false)
                            .getValidAccessToken();
                    try {
                      var response = await http.post(
                          Uri.parse('http://localhost:8884/v1/updateIcon'),
                          body: encData,
                          headers: <String, String>{
                            'Content-Type': 'application/json',
                            'Authorization': "Bearer $accessToken",
                          });
                      print(
                          "Update icon response ${response.statusCode} ${response.body}");
                      setState(() {
                        errOnUpload = false;
                      });
                      BlocProvider.of<FilePickerCubit>(context, listen: false)
                          .updateFilePicker(media: Map(), filesAttached: 0);
                      updateImage.sink.add(true);
                      Provider.of<GroupsList>(context, listen: false)
                          .triggerRerender();
                    } catch (e) {
                      print("Exception occured in update icon $e");
                      setState(() {
                        errOnUpload = true;
                      });
                    }
                  },
                ),
              ),
              BlocBuilder<GroupMetadataCubit, GroupMetadataMap>(
                builder: (context, state) {
                  return _createForm(
                      this.widget.data["groupId"],
                      state.data[this.widget.data["groupId"]] == null
                          ? ""
                          : state.data[this.widget.data["groupId"]]!.name,
                      state.data[this.widget.data["groupId"]] == null
                          ? ""
                          : state
                              .data[this.widget.data["groupId"]]!.description);
                },
              )
            ],
          ),
        ));
  }
}

class CheckBox extends StatefulWidget {
  final String title;
  final String id;
  bool value = false;
  CheckBox({
    required this.title,
    required this.id,
  });
  @override
  _CheckBoxState createState() => _CheckBoxState();
}

class _CheckBoxState extends State<CheckBox> {
  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
        value: widget.value,
        title: Text(widget.title),
        onChanged: (value) => setState(() => widget.value = value!));
  }
}
