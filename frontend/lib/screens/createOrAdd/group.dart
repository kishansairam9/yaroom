import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/types.dart';

class CreateGroup extends StatelessWidget {
  _addMembers(context, data) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext c) {
          return ListView.builder(
              itemCount: data!.length,
              itemBuilder: (context, index) {
                // var result = data![index];
                // User f = User(
                //     name: result.name,
                //     about: result.about,
                //     profileImg: result.profileImg,
                //     userId: result.userId);
                if (data[index].status != 2)
                  return const SizedBox(
                    height: 0,
                  );
                return CheckboxListTile(
                    title: Text(data[index].name),
                    secondary: CircleAvatar(
                      backgroundColor: Colors.grey[350],
                      foregroundImage: data[index].profileImg == null
                          ? null
                          : NetworkImage('${data[index].profileImg}'),
                      backgroundImage: AssetImage('assets/no-profile.png'),
                    ),
                    value: true,
                    onChanged: (_) => {});
              });
        });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: RepositoryProvider.of<AppDb>(context).getFriendRequests().get(),
        builder: (BuildContext context,
            AsyncSnapshot<List<GetFriendRequestsResult>> snapshot) {
          if (snapshot.hasData) {
            return TextButton(
                onPressed: () => _addMembers(context, snapshot.data),
                child: Text("Hey"));
          }
          return Container();
        });
  }
}
