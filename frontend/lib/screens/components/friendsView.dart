import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:yaroom/utils/backendRequests.dart';
import '../../utils/types.dart';
import '../../utils/notifiers.dart';
import 'contactView.dart';
import '../edit/friend.dart';
import '../../blocs/activeStatus.dart';

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
                    ListView(
                        children:
                            snapshot.data!.map((GetFriendRequestsResult e) {
                      if (e.status != FriendRequestType.friend.index) {
                        return const SizedBox(
                          height: 0,
                        );
                      }
                      return BlocBuilder<ActiveStatusCubit, bool>(
                          bloc: Provider.of<ActiveStatusMap>(context)
                              .get(e.userId),
                          builder: (context, state) {
                            return ListTile(
                              onTap: () => showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext c) {
                                    return ViewContact(e);
                                  }),
                              tileColor: Colors.transparent,
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.grey[350],
                                    foregroundImage: iconImageWrapper(e.userId),
                                  ),
                                  Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                          width: 15,
                                          height: 15,
                                          decoration: new BoxDecoration(
                                            color: state
                                                ? Colors.green
                                                : Colors.grey,
                                            shape: BoxShape.circle,
                                          )))
                                ],
                              ),
                              title: Text(
                                e.name,
                              ),
                              trailing: IconButton(
                                  onPressed: () => Navigator.of(context)
                                      .pushNamed('/chat',
                                          arguments: ChatPageArguments(
                                              userId: e.userId, name: e.name)),
                                  icon: Icon(Icons.message_rounded)),
                            );
                          });
                    }).toList()),
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
                                    snapshot.data![index].status ==
                                            FriendRequestType.pending
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
                                  if (result.status !=
                                      FriendRequestType.pending)
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
                                          (direction ==
                                                  DismissDirection.endToStart)
                                              ? FriendRequestType.friend.index
                                              : FriendRequestType.reject.index,
                                          context);
                                      await RepositoryProvider.of<AppDb>(
                                              context)
                                          .updateFriendRequest(
                                              status: (direction ==
                                                      DismissDirection
                                                          .endToStart)
                                                  ? FriendRequestType
                                                      .friend.index
                                                  : FriendRequestType
                                                      .pending.index,
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
