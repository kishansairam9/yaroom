import 'package:flutter/material.dart';
import 'package:yaroom/chat.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Title',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blueGrey[600],
        accentColor: Colors.grey[300],
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey[600],
        accentColor: Colors.black38,
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: ChatView(),
    );
  }
}
