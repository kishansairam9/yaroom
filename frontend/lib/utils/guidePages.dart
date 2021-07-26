import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('No such route'),
      color: Colors.lightGreen[400],
    );
  }
}

class SelectRoomPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Select a room'),
      color: Colors.brown[300],
    );
  }
}

class SelectChannelPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Select a channel'),
      color: Colors.orange[300],
    );
  }
}
