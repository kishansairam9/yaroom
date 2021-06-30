import 'package:flutter/material.dart';
import 'router.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final _contentRouter = ContentRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'yaroom',
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
      onGenerateRoute: _contentRouter.onGenerateRoute,
    );
  }
}
