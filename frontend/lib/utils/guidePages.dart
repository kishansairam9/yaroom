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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image(
              image: AssetImage('assets/yaroom.png'),
              width: 100,
            ),
            SizedBox(height: 20),
            Container(
              child: Text(
                "Please Select a Room",
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SelectChannelPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image(
              image: AssetImage('assets/yaroom.png'),
              width: 100,
            ),
            SizedBox(height: 20),
            Container(
              child: Text(
                "Please Select a Channel",
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );  }
}
