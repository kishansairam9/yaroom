import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../utils/types.dart';
import 'contactView.dart';

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
        future: RepositoryProvider.of<AppDb>(context)
            .getFriendRequests(
                userId: Provider.of<UserId>(context, listen: false))
            .get(),
        builder: (BuildContext context,
            AsyncSnapshot<List<GetFriendRequestsResult>> snapshot) {
          if (snapshot.hasData) {
            return DefaultTabController(
              length: 3,
              child: Scaffold(
                // floatingActionButton: FloatingActionButton(
                //     onPressed: () => _showFriendRequests(context,
                //         snapshot.data!.where((element) => element.st == 1)),
                //     child: Icon(Icons.person_add),
                //     backgroundColor: Theme.of(context).primaryColor),
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
                              profileImg: result.profileImg,
                              userId: result.userId);
                          if (result.st != 2)
                            return const SizedBox(
                              height: 0,
                            );
                          return ListTile(
                            onTap: () => _showContact(context, f),
                            leading: CircleAvatar(
                                backgroundImage:
                                    AssetImage('assets/no-profile.png'),
                                foregroundImage: f.profileImg == null
                                    ? null
                                    : NetworkImage('${f.profileImg}')),
                            title: Text(f.name),
                            subtitle: Text("Active"),
                            trailing: IconButton(
                                onPressed: () => Navigator.of(context)
                                    .pushNamed('/chat',
                                        arguments: ChatPageArguments(
                                            userId: f.userId,
                                            name: f.name,
                                            image: f.profileImg)),
                                icon: Icon(Icons.message_rounded)),
                          );
                        }),
                    Scaffold(
                      // bottomSheet: Text.rich(TextSpan(text:" Swipe Left or Right to Accept or Delete requests "), textAlign: TextAlign.justify,),
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
                                    snapshot.data![index].st == 1
                                        ? const Divider()
                                        : SizedBox(
                                            height: 0,
                                          ),
                                itemBuilder: (context, index) {
                                  var result = snapshot.data![index];
                                  User f = User(
                                      name: result.name,
                                      about: result.about,
                                      profileImg: result.profileImg,
                                      userId: result.userId);
                                  if (result.st != 1)
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
                                      await RepositoryProvider.of<AppDb>(
                                              context)
                                          .updateFriendRequest(
                                              status: direction ==
                                                      DismissDirection
                                                          .endToStart
                                                  ? 2
                                                  : 3,
                                              userId_1: Provider.of<UserId>(
                                                  context,
                                                  listen: false),
                                              userId_2: f.userId);
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
                                          backgroundImage: AssetImage(
                                              'assets/no-profile.png'),
                                          foregroundImage: f.profileImg == null
                                              ? null
                                              : NetworkImage(
                                                  '${f.profileImg}')),
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

class AddFriend extends StatefulWidget {
  const AddFriend({Key? key}) : super(key: key);

  @override
  AddFriendState createState() {
    return AddFriendState();
  }
}

class AddFriendState extends State<AddFriend> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Add your Friends!",textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headline6!),
            TextFormField(
              decoration: const InputDecoration(
                  icon: Icon(Icons.person_add), labelText: 'Enter Username'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter username';
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Processing Data')),
                    );
                  }
                },
                child: const Text('Send Friend Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
