import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yaroom/utils/types.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var media = new Map();

  Future<void> _openFileExplorer() async {
    FilePickerResult? _paths =
        await FilePicker.platform.pickFiles(withData: true);
    if (_paths != null) {
      media['name'] = _paths.files.first.name;
      media['bytes'] = _paths.files.first.bytes;

      BlocProvider.of<FilePickerCubit>(context, listen: false)
          .updateFilePicker(media: media, i: 1);
    }
    // Use as
    // BlocProvider.of<FilePickerCubit>(context, listen: false).state.media;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image(image: iconImageWrapper(Provider.of<UserId>(context))),
            Container(
              child: TextButton(
                child: Text("Update Image"),
                onPressed: () async {
                  await _openFileExplorer();
                  // TODO USE DATA FROM CUBIT AND THEN UPLOAD using backend route, UPDATE STUFF
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
