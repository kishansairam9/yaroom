import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:yaroom/utils/authorizationService.dart';
import 'chatsView.dart';
import 'groupsView.dart';
import '../components/roomsList.dart';
import '../../utils/types.dart';

class TabView extends StatefulWidget {
  static TabViewState? of(BuildContext context) =>
      context.findAncestorStateOfType<TabViewState>();

  @override
  TabViewState createState() => TabViewState();
}

class TabViewState extends State<TabView> {
  double cumSum = 0;
  int counter = 0;
  bool startedLeftOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('yaroom'),
        bottomOpacity: 0.0,
        elevation: 0.0,
        leading: Builder(
          builder: (context) {
            return IconButton(
                icon: Image.asset("assets/yaroom.png"),
                onPressed: () => {Scaffold.of(context).openDrawer()});
          },
        ),
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
                delegate: TabViewSearchDelegate(),
              );
            },
            tooltip: 'Search',
          ),
        ],
      ),
      drawer: Container(
          width: MediaQuery.of(context).size.width * 0.2,
          // padding: new EdgeInsets.all(10.0),
          child: Drawer(
            // child: RoomListView(),
            child: SafeArea(
              child: Column(
                children: [
                  IconButton(
                      padding: EdgeInsets.all(4),
                      icon: Icon(Icons.home, size: 30),
                      onPressed: () => {}),
                  Divider(),
                  Expanded(child: RoomListView())
                ],
              ),
            ),
          )),
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
                      )),
              Center(
                child: GroupChatView(),
              ),
            ],
          ),
        ),
      ),
    );
    //   }),
    // );
  }
}

class TabViewSearchDelegate extends SearchDelegate {
  late final List tiles;

  TabViewSearchDelegate() : super();

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

  Future<Widget> search(BuildContext context) async {
    if (query.isEmpty) {
      return Center(
        child: Text("Enter query"),
      );
    }
    var textresults = await RepositoryProvider.of<AppDb>(context)
        .searchChatMessages(query: query.toLowerCase(), limit: 50)
        .get();
    var usersMatching = await RepositoryProvider.of<AppDb>(context)
        .getUsersNameMatching(match: query.toLowerCase())
        .get();

    var groupTextResults = await RepositoryProvider.of<AppDb>(context)
        .searchGroupChatMessages(query: query.toLowerCase(), limit: 50)
        .get();
    var groupsMatching = await RepositoryProvider.of<AppDb>(context)
        .getGroupsNameMatching(match: query.toLowerCase())
        .get();
    // print("Queried ${query.toLowerCase()}");
    List<SearchChatMessagesResult> userResults = usersMatching
        .map((e) => SearchChatMessagesResult(
            content: '',
            userId: e.userId,
            name: e.name,
            profileImg: e.profileImg))
        .toList();
    List<SearchGroupChatMessagesResult> groupResults = groupsMatching
        .map((e) => SearchGroupChatMessagesResult(
            content: '',
            groupId: e.groupId,
            name: e.name,
            groupIcon: e.groupIcon))
        .toList();
    var chatResults = userResults + textresults;
    var groupDMresults = groupResults + groupTextResults;
    // print(results.map((e) => e.name));
    // print(results.map((e) => e.content));
    if (chatResults.isEmpty && groupDMresults.isEmpty) {
      return Center(
        child: Text("No matches"),
      );
    }
    var chatResultsList = chatResults
        .map((SearchChatMessagesResult e) => ProfileTile(
            userId: e.userId,
            image: e.profileImg,
            name: e.name,
            unread: 0,
            showText: e.content,
            preShowChat: close,
            preParams: [context, null]))
        .toList();
    var groupDMresultslist = groupDMresults
        .map((SearchGroupChatMessagesResult e) => GroupProfileTile(
            groupId: e.groupId,
            image: e.groupIcon,
            name: e.name,
            unread: 0,
            showText: e.content,
            preShowChat: close,
            preParams: [context, null]))
        .toList();

    var finalResults = [...chatResultsList, ...groupDMresultslist];

    return ListView(
        children: ListTile.divideTiles(
            context: context,
            tiles: results.map((SearchChatMessagesResult e) => ProfileTile(
                userId: e.userId,
                image: e.profileImg,
                name: e.name,
                unread: 0,
                showText: e.content,
                preShowChat: close,
                preParams: [context, null]))).toList());
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
        future: search(context),
        builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return SnackBar(
                content: Text('Error has occured while reading from local DB'));
          }
          return CircularProgressIndicator();
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
        future: search(context),
        builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return SnackBar(
                content: Text('Error has occured while reading from local DB'));
          }
          return CircularProgressIndicator();
        });
  }
}
