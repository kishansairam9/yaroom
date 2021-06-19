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
      home: TabView(),
    );
  }
}

class TabViewSearchDelegate extends SearchDelegate {
  late final List tiles;

  TabViewSearchDelegate(view) {
    // REQUIREMENT => view variable has tiles getter, else will crash
    // TODO WARN: Couldn't find a better wat to force tiles
    // This works because of dynamic typing in dart, but we need to ensure stricter
    // and more complete tests or else it will fail
    tiles = view.tiles;
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
          onPressed: () => {close(context, null)},
          icon: Icon(Icons.close),
          tooltip: 'Cancel')
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        onPressed: () => {close(context, null)},
        icon: Icon(Icons.arrow_back),
        tooltip: 'Cancel');
  }

  Widget nameSearch(BuildContext context) {
    var results = tiles
        .where((x) => x.name.toLowerCase().contains(query.toLowerCase()))
        .map((e) {
      return Card(
        child: ListTile(
          onTap: () {
            close(context, null); // TODO: Is this casuing buggy transisiton?
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (BuildContext context) {
              return ChatPage(name: e.name, image: e.image);
            }));
          },
          leading: CircleAvatar(
            backgroundColor: Colors.grey[350],
            foregroundImage: NetworkImage('${e.image}'),
            backgroundImage: AssetImage('assets/no-profile.png'),
          ),
          title: Text(e.name),
        ),
      );
    }).toList();
    if (results.isEmpty) {
      return Center(
        child: Text("No matches"),
      );
    }
    return ListView(children: results);
  }

  @override
  Widget buildResults(BuildContext context) {
    return nameSearch(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return nameSearch(context);
  }
}

class TabView extends StatelessWidget {
  final views = [
    ChatView(),
    Center(
      child: Text("Groups here"),
    ),
    Center(
      child: Text("Rooms here"),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        initialIndex: 1,
        length: 3,
        child: Builder(builder: (BuildContext context) {
          final TabController tabController = DefaultTabController.of(context)!;
          int viewIndex = 0;
          tabController.addListener(() {
            if (!tabController.indexIsChanging) {
              viewIndex = tabController.index;
            }
          });
          return Scaffold(
            appBar: AppBar(
              title: const Text('yaroom'),
              actions: <Widget>[
                IconButton(
                  onPressed: () => {},
                  icon: Icon(Icons.settings_applications),
                  tooltip: 'Settings',
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      // TODO: Currently using only chats for ChatView, replace with contact list or something like that
                      delegate: TabViewSearchDelegate(views[viewIndex]),
                    );
                  },
                  tooltip: 'Search',
                ),
              ],
              bottom: const TabBar(
                tabs: <Widget>[
                  Tab(
                    icon: Icon(Icons.message_rounded),
                  ),
                  Tab(
                    icon: Icon(Icons.groups_rounded),
                  ),
                  Tab(
                    // TODO: Better icon for rooms
                    icon: Icon(Icons.cloud),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: views,
            ),
          );
        }));
  }
}
