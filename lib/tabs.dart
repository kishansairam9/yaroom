import 'package:flutter/material.dart';
import 'chat.dart';
import 'rooms.dart';
import 'inner_drawer.dart';

class TabView extends StatefulWidget {
  static TabViewState? of(BuildContext context) =>
      context.findAncestorStateOfType<TabViewState>();

  @override
  TabViewState createState() => TabViewState();
}

class TabViewState extends State<TabView> {
  //  Current State of InnerDrawerState
  final GlobalKey<InnerDrawerState> _innerDrawerKey =
      GlobalKey<InnerDrawerState>();

  void toggle() {
    _innerDrawerKey.currentState!.toggle();
  }

  @override
  Widget build(BuildContext context) {
    return InnerDrawer(
      key: _innerDrawerKey,
      leftChild: RoomsList(
        animateInsteadOfNavigateHome: true,
      ),
      scaffold: Builder(builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('yaroom'),
            leading: IconButton(
              icon: Icon(Icons.radar),
              onPressed: () => {TabView.of(context)?.toggle()},
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
