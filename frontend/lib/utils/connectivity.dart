import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:yaroom/utils/types.dart';

class ConnectivityCheck extends StatefulWidget {
  late final Widget child;
  late final Stream<ConnectivityFlags> connectionStream;
  ConnectivityCheck({required this.child, required this.connectionStream});

  @override
  ConnectivityCheckState createState() => ConnectivityCheckState();
}

class ConnectivityCheckState extends State<ConnectivityCheck> {
  bool hasConnection = false;
  bool onceInitialized = false;
  ConnectivityCheckState();

  @override
  initState() {
    super.initState();
    loopCheck();
    widget.connectionStream.listen(checkInitialized);
  }

  void checkInitialized(ConnectivityFlags conn) {
    switch (conn) {
      case ConnectivityFlags.closed:
        onceInitialized = false;
        setState(() {
          hasConnection = false;
        });
        break;
      case ConnectivityFlags.wsActive:
        onceInitialized = true;
        if (!hasConnection) {
          setState(() {
            hasConnection = true;
          });
        }
        break;
      case ConnectivityFlags.wsRetrying:
        if (hasConnection) {
          setState(() {
            hasConnection = false;
          });
        }
        break;
    }
  }

  void loopCheck() async {
    while (true) {
      if (!onceInitialized) {
        bool prevState = hasConnection;
        bool nextState;
        try {
          var resp = await http.get(Uri.parse('http://localhost:8884/icon'));
          print(resp.statusCode);
          nextState = resp.statusCode == 200;
          print(nextState);
        } catch (e) {
          nextState = false;
        }
        if (prevState != nextState) {
          setState(() {
            hasConnection = nextState;
          });
        }
      }
      await Future.delayed(Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasConnection) {
      return Container(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Image(image: AssetImage('assets/yaroom_full_logo_200x200.png')),
              Container(
                child: Text(
                  'Cant reach backend!\nPlease check network\nIf issue persists, contact support',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
        ),
      );
    } else {
      return widget.child;
    }
  }
}
