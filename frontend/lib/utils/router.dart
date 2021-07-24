import 'package:flutter/material.dart';
import '../screens/home/tabs.dart';
import 'errorPage.dart';
import '../screens/rooms/room.dart';
import './types.dart';

// TODO: Currently visiting any random route on web crashes the app FIX THIS

class ContentRouter {
  Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => TabView());
      case '/rooms':
        final args = settings.arguments as RoomArguments;
        return MaterialPageRoute(
            builder: (_) => Room(
                roomId: args.roomId,
                roomName: args.roomName));
      default:
        return MaterialPageRoute(builder: (_) => ErrorPage());
    }
  }
}
