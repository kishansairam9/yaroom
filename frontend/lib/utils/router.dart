import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/home/tabs.dart';
import 'errorPage.dart';
import '../screens/rooms/room.dart';
import '../login.dart';
// TODO: Currently visiting any random route on web crashes the app FIX THIS

class ContentRouter {
  Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/signin':
        return MaterialPageRoute(
            builder: (_) => Consumer<LandingViewModel>(
                builder: (_, LandingViewModel viewModel, __) =>
                    LandingPage(viewModel)));
      case '/tabs':
        return MaterialPageRoute(builder: (_) => TabView());
      case '/rooms':
        return MaterialPageRoute(builder: (_) => Rooms());
      default:
        return MaterialPageRoute(builder: (_) => ErrorPage());
    }
  }
}
