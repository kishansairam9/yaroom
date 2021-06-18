import 'package:flutter/material.dart';
import './chat.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('yaroom'),
        actions: <Widget>[
          IconButton(
            onPressed: () => {},
            icon: Icon(Icons.settings_applications),
            tooltip: 'Settings',
          )
        ],
      ),
      body: ChatView(),
    );
  }
}
