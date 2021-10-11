import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:yaroom/utils/backendRequests.dart';
import '../../utils/types.dart';
import '../../utils/notifiers.dart';
import 'contactView.dart';
import '../createOrAdd/friend.dart';
import '../messaging/chatsView.dart';

class FriendsView extends StatefulWidget {
  const FriendsView({Key? key}) : super(key: key);
  @override
  _FriendsViewState createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  _showContact(context, User f) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext c) {
          return ViewContact(f);
        });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: RepositoryProvider.of<AppDb>(context).getFriendRequests().get(),
        builder: (BuildContext context,
            AsyncSnapshot<List<GetFriendRequestsResult>> snapshot) {
          if (snapshot.hasData) {
            return DefaultTabController(
              length: 3,
              child: Scaffold(
                appBar: AppBar(
                  bottomOpacity: 0.0,
                  elevation: 0.0,
                  leading: Container(),
                  flexibleSpace: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TabBar(
                        tabs: [
                          Tab(
                            child: Text("Friends"),
                          ),
                          Tab(
                            child: Text("Pending"),
                          ),
                          Tab(
                            child: Text("Add Friend"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          var result = snapshot.data![index];
                          User f = User(
                              name: result.name,
                              about: result.about,
                              userId: result.userId);
                          if (result.status != 2)
                            return const SizedBox(
                              height: 0,
                            );
                          return ListTile(
                            onTap: () => _showContact(context, f),
                            leading: CircleAvatar(
                                foregroundImage: iconImageWrapper(f.userId)),
                            title: Text(f.name),
                            subtitle: Text("Active"),
                            trailing: IconButton(
                                onPressed: () => Navigator.of(context)
                                    .pushNamed('/chat',
                                        arguments: ChatPageArguments(
                                            userId: f.userId, name: f.name)),
                                icon: Icon(Icons.message_rounded)),
                          );
                        }),
                    Scaffold(
                      bottomSheet: Container(
                          height: 40,
                          width: MediaQuery.of(context).size.width,
                          child: Center(
                              child: Text(
                            'Swipe Left or Right to Accept or Delete requests',
                            style: TextStyle(
                                color: Theme.of(context).primaryColorLight),
                          ))),
                      body: SingleChildScrollView(
                        // physics: ScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListView.separated(
                                shrinkWrap: true,
                                // scrollDirection: Axis.vertical,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.length,
                                separatorBuilder: (_, index) =>
                                    snapshot.data![index].status == 1
                                        ? const Divider()
                                        : SizedBox(
                                            height: 0,
                                          ),
                                itemBuilder: (context, index) {
                                  var result = snapshot.data![index];
                                  User f = User(
                                      name: result.name,
                                      about: result.about,
                                      userId: result.userId);
                                  if (result.status != 1)
                                    return const SizedBox(
                                      height: 0,
                                    );
                                  return Dismissible(
                                    background: Container(
                                        padding:
                                            const EdgeInsets.only(left: 10.0),
                                        child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Icon(Icons.person_remove)),
                                        color: Colors.red),
                                    secondaryBackground: Container(
                                        padding:
                                            const EdgeInsets.only(right: 10.0),
                                        child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Icon(Icons.person_add)),
                                        color: Colors.green),
                                    onDismissed:
                                        (DismissDirection direction) async {
                                      await friendRequest(
                                          f.userId,
                                          direction ==
                                                  DismissDirection.endToStart
                                              ? 2
                                              : 3,
                                          context);
                                      await RepositoryProvider.of<AppDb>(
                                              context)
                                          .updateFriendRequest(
                                              status: direction ==
                                                      DismissDirection
                                                          .endToStart
                                                  ? 2
                                                  : 3,
                                              userId: f.userId);
                                      await Provider.of<DMsList>(context,
                                              listen: false)
                                          .updateChats(context);
                                      setState(() {
                                        snapshot.data!.removeAt(index);
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(direction ==
                                                      DismissDirection
                                                          .endToStart
                                                  ? "Added as Friend!"
                                                  : "Request Deleted.")));
                                    },
                                    key: ValueKey<GetFriendRequestsResult>(
                                        snapshot.data![index]),
                                    child: ListTile(
                                      onTap: () => _showContact(context, f),
                                      leading: CircleAvatar(
                                          foregroundImage:
                                              iconImageWrapper(f.userId)),
                                      title: Text(f.name),
                                    ),
                                  );
                                }),
                            SizedBox(
                              height: 40,
                            ),
                          ],
                        ),
                      ),
                    ),
                    AddFriend()
                  ],
                ),
              ),
            );
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return SnackBar(
                content: Text('Error has occured while reading from DB'));
          }
          return Container();
        });
  }
}
