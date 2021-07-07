import 'package:flutter/material.dart';
import 'chatsView.dart';
import '../components/roomsList.dart';
import '../../utils/inner_drawer.dart';

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
  double cumSum = 0;
  int counter = 0;
  bool startedLeftOpen = false;

  void toggle() {
    _innerDrawerKey.currentState!.toggle();
  }

  void open() {
    _innerDrawerKey.currentState!.open();
  }

  void close() {
    _innerDrawerKey.currentState!.close();
  }

  void dragUpdate(var details) {
    _innerDrawerKey.currentState!.dragUpdate(details);
  }

  void dragEnd(var details) {
    _innerDrawerKey.currentState!.dragEnd(details);
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
            bottomOpacity: 0.0,
            elevation: 0.0,
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
                automaticallyImplyLeading: false,
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
                  Builder(
                      builder: (context) => GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            child: ChatView(),
                            onHorizontalDragEnd: (details) {
                              if (startedLeftOpen) startedLeftOpen = false;
                              dragEnd(details);
                            },
                            onHorizontalDragUpdate: (details) {
                              cumSum += details.delta.dx;
                              counter += 1;
                              if (counter < 4) return;
                              if (cumSum / counter > 0.5 &&
                                  details.delta.dx > 0) {
                                startedLeftOpen = true;
                                for (int i = 0;
                                    i < (counter.toDouble() * 0.75).round();
                                    i++) dragUpdate(details);
                                counter = 0;
                                cumSum = 0;
                              } else if (cumSum / counter < -0.5) {
                                if (startedLeftOpen) {
                                  close();
                                  counter = 0;
                                  cumSum = 0;
                                  return;
                                }
                                final TabController tabController =
                                    DefaultTabController.of(context)!;
                                if ((tabController.index + 1) <
                                    tabController.length)
                                  tabController
                                      .animateTo((tabController.index + 1));
                                counter = 0;
                                cumSum = 0;
                              }
                              if (counter >= 6) {
                                counter = 0;
                                cumSum = 0;
                              }
                            },
                          )),
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
