import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../utils/types.dart';
import 'contactView.dart';

class FriendsView extends StatelessWidget {
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
            .getFriends(userId: Provider.of<UserId>(context, listen: false))
            .get(),
        builder: (BuildContext context, AsyncSnapshot<List<User>> snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              floatingActionButton: FloatingActionButton(
                  onPressed: () => {},
                  child: Icon(Icons.person_add),
                  backgroundColor: Theme.of(context).primaryColor),
              body: ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    User f = snapshot.data![index];
                    return ListTile(
                      onTap: () => _showContact(context, f),
                      leading: CircleAvatar(
                          backgroundImage: AssetImage('assets/no-profile.png'),
                          foregroundImage: f.profileImg == null
                              ? null
                              : NetworkImage('${f.profileImg}')),
                      title: Text(f.name),
                      subtitle: Text("Active"),
                      trailing: IconButton(
                          onPressed: () => Navigator.of(context).pushNamed(
                              '/chat',
                              arguments: ChatPageArguments(
                                  userId: f.userId,
                                  name: f.name,
                                  image: f.profileImg)),
                          icon: Icon(Icons.message_rounded)),
                    );
                  }),
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
