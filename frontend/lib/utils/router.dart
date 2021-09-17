import 'package:flutter/material.dart';
import '../screens/homePage.dart';
import '../screens/settingsPage.dart';
import '../screens/messaging/chatPage.dart';
import '../screens/messaging/groupPage.dart';
import 'guidePages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../screens/login.dart';
import './types.dart';
import './authorizationService.dart';
import '../screens/createOrAdd/group.dart';

Widget wrapWithUserId(BuildContext context, Widget child) {
  return FutureBuilder<String>(
      future:
          Provider.of<AuthorizationService>(context, listen: false).getUserId(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Provider<UserId>(create: (_) => snapshot.data!, child: child);
        } else {
          return CircularProgressIndicator();
        }
      });
}

// TODO: Currently visiting any random route on web crashes the app FIX THIS

class ContentRouter {
  Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        final args = settings.arguments == null
            ? HomePageArguments()
            : settings.arguments as HomePageArguments;
        return MaterialPageRoute(
            builder: (context) => wrapWithUserId(context, HomePage(args)));
      case '/chat':
        final args = settings.arguments as ChatPageArguments;
        return MaterialPageRoute(
            builder: (context) => wrapWithUserId(context, ChatPage(args)));
      case '/groupchat':
        final args = settings.arguments as GroupChatPageArguments;
        return MaterialPageRoute(
            builder: (context) => wrapWithUserId(context, GroupChatPage(args)));
      case '/signin':
        return MaterialPageRoute(
            builder: (_) => Consumer<LandingViewModel>(
                builder: (_, LandingViewModel viewModel, __) =>
                    LandingPage(viewModel)));
      case '/room':
        final args = settings.arguments as RoomArguments;
        return MaterialPageRoute(
            builder: (context) => wrapWithUserId(context, HomePage(args)));
      case '/editgroup':
        final args = settings.arguments;
        return MaterialPageRoute(
            builder: (context) => wrapWithUserId(context, CreateGroup(args)));

      case '/settings':
        return MaterialPageRoute(
            builder: (context) => wrapWithUserId(
                context,
                BlocProvider(
                  create: (context) {
                    return FilePickerCubit(
                        initialState:
                            FilePickerDetails(media: Map(), filesAttached: 0));
                  },
                  child: SettingsPage(),
                )));

      default:
        return MaterialPageRoute(builder: (_) => ErrorPage());
    }
  }
}
