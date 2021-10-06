import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yaroom/utils/backendRequests.dart';
import 'package:yaroom/utils/types.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/authorizationService.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
      media['iconId'] = Provider.of<UserId>(context, listen: false);
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
    // Use as
    // BlocProvider.of<FilePickerCubit>(context, listen: false).state.media;
  }

  Future<Widget> _createForm() async {
    List<User> data = await RepositoryProvider.of<AppDb>(context)
        .getUserById(userId: Provider.of<UserId>(context, listen: false))
        .get();
    var _userData = {
      "userId": data[0].userId,
      "name": data[0].name,
      "about": data[0].about,
    };
    print(_userData);
    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: data[0].name,
              decoration: const InputDecoration(
                  icon: Icon(Icons.person_add), labelText: 'Enter User Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter User name';
                } else {
                  _userData["name"] = value;
                }
                return null;
              },
            ),
            TextFormField(
              initialValue: data[0].about,
              decoration: const InputDecoration(
                  icon: Icon(Icons.text_snippet),
                  labelText: 'Write about Yourself'),
              validator: (value) {
                if (value == null) {
                  return 'Please enter description';
                } else {
                  _userData["about"] = value;
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
                    await editUser(
                        jsonEncode(<String, dynamic>{
                          "userId": _userData["userId"],
                          "name": _userData["name"],
                          "about": _userData["about"],
                        }),
                        context);
                    await RepositoryProvider.of<AppDb>(context, listen: false)
                        .addUser(
                            userId: _userData["userId"]!,
                            name: _userData["name"]!,
                            about: _userData["about"]!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Processing Data')),
                    );
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
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back))),
            title: Text("Settings")),
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
                          image: iconImageWrapper(
                              Provider.of<UserId>(context, listen: false)));
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
                    } catch (e) {
                      print("Exception occured in update icon $e");
                      setState(() {
                        errOnUpload = true;
                      });
                    }
                  },
                ),
              ),
              FutureBuilder<Widget>(
                  future: _createForm(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }
                    return snapshot.data!;
                  })
            ],
          ),
        ));
  }
}
  // @override
  // Widget build(BuildContext context) {
  //   return Container(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         crossAxisAlignment: CrossAxisAlignment.center,
  //         children: <Widget>[
  //           errOnUpload
  //               ? SnackBar(
  //                   content: Text('Error occured while uploading retry!'))
  //               : Container(),
  //           StreamBuilder(
  //               stream: updateImage.stream,
  //               builder: (context, snapshot) {
  //                 if (snapshot.hasData) {
  //                   return Image(
  //                       image: iconImageWrapper(
  //                           Provider.of<UserId>(context, listen: false)));
  //                 }
  //                 return CircularProgressIndicator();
  //               }),
  //           Container(
  //             child: TextButton(
  //               child: Text("Update Image"),
  //               onPressed: () async {
  //                 await _openFileExplorer();
  //                 String encData = jsonEncode(
  //                     BlocProvider.of<FilePickerCubit>(context, listen: false)
  //                         .state
  //                         .media);
  //                 final String? accessToken =
  //                     await Provider.of<AuthorizationService>(context,
  //                             listen: false)
  //                         .getValidAccessToken();
  //                 try {
  //                   var response = await http.post(
  //                       Uri.parse('http://localhost:8884/v1/updateIcon'),
  //                       body: encData,
  //                       headers: <String, String>{
  //                         'Content-Type': 'application/json',
  //                         'Authorization': "Bearer $accessToken",
  //                       });
  //                   print(
  //                       "Update icon response ${response.statusCode} ${response.body}");
  //                   setState(() {
  //                     errOnUpload = false;
  //                   });
  //                   BlocProvider.of<FilePickerCubit>(context, listen: false)
  //                       .updateFilePicker(media: Map(), filesAttached: 0);
  //                   updateImage.sink.add(true);
  //                 } catch (e) {
  //                   print("Exception occured in update icon $e");
  //                   setState(() {
  //                     errOnUpload = true;
  //                   });
  //                 }
  //               },
  //             ),
  //           )
  //         ],
  //       ),
  //     ),
  //   );
  // }
// }
