import 'package:flutter/material.dart';
import 'chat.dart';
import 'pullLeft.dart';
import 'rooms.dart';

class TabView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PullLeftWrapper(
      leftContent: RoomsList(
        animateInsteadOfNavigateHome: true,
      ),
      mainContent: Builder(builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('yaroom'),
            leading: IconButton(
              icon: Icon(Icons.radar),
              onPressed: () => {PullLeftWrapper.of(context)?.toggle()},
            ),
            actions: <Widget>[
              IconButton(
                onPressed: () => {},
                icon: Icon(Icons.settings_applications),
                tooltip: 'Settings',
              ),
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {},
                tooltip: 'Search',
              ),
            ],
          ),
          body: DefaultTabController(
            initialIndex: 0,
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const TabBar(
                  tabs: <Widget>[
                    Tab(
                      icon: Icon(Icons.message_rounded),
                    ),
                    Tab(
                      icon: Icon(Icons.groups_rounded),
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                children: <Widget>[
                  ChatView(),
                  Center(
                    child: Text("Groups here"),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
