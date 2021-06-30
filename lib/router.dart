import 'package:flutter/material.dart';
import 'tabs.dart';
import 'errorPage.dart';
import 'rooms.dart';

// TODO: Currently visiting any random route on web crashes the app FIX THIS

class ContentRouter {
  Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => TabView());
      case '/rooms':
        return MaterialPageRoute(builder: (_) => Rooms());
      default:
        return MaterialPageRoute(builder: (_) => ErrorPage());
    }
  }
}
