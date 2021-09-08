import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/types.dart';

class CreateGroup extends StatefulWidget {
  final data;
  CreateGroup(this.data);

  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  final _formKey = GlobalKey<FormState>();
  List<dynamic> checklist = [];
  _addMembers() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext c) {
          return FutureBuilder(
              future: RepositoryProvider.of<AppDb>(context)
                  .getFriendRequests()
                  .get(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<GetFriendRequestsResult>> snapshot) {
                if (snapshot.hasData) {
                  return Scaffold(
                    appBar: AppBar(
                      leading: Builder(
                          builder: (context) => IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.arrow_back))),
                      title: Text("Add more people!"),
                      actions: [
                        TextButton(
                            onPressed: () => {},
                            child: Text(
                              "ADD",
                              style: TextStyle(color: Colors.white),
                            ))
                      ],
                    ),
                    body: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            print("Hello");
                            print(checklist);
                            if ((snapshot.data![index].status != 2) ||
                                (this
                                    .widget
                                    .data["members"]
                                    .contains(snapshot.data![index].userId)))
                              return const SizedBox(
                                height: 0,
                              );
                            return CheckboxListTile(
                                title: Text(snapshot.data![index].name),
                                secondary: CircleAvatar(
                                  backgroundColor: Colors.grey[350],
                                  foregroundImage: snapshot
                                              .data![index].profileImg ==
                                          null
                                      ? null
                                      : NetworkImage(
                                          '${snapshot.data![index].profileImg}'),
                                  backgroundImage:
                                      AssetImage('assets/no-profile.png'),
                                ),
                                value: checklist
                                    .contains(snapshot.data![index].userId),
                                onChanged: (_) {
                                  setState(() {
                                    if (checklist
                                        .contains(snapshot.data![index].userId))
                                      checklist.removeWhere((element) =>
                                          element ==
                                          snapshot.data![index].userId);
                                    else
                                      checklist
                                          .add(snapshot.data![index].userId);
                                    print(checklist);
                                  });
                                });
                          }),
                    ),
                  );
                } else if (snapshot.hasError) {
                  print(snapshot.error);
                  return SnackBar(
                      content: Text(
                          'Error has occured while reading from local DB'));
                }
                return Container();
              });
        });
  }

  _createForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Text("Add your friends to the group",
            //     textAlign: TextAlign.center,
            //     style: Theme.of(context).textTheme.headline6!),
            TextFormField(
              initialValue: this.widget.data["group"].name,
              decoration: const InputDecoration(
                  icon: Icon(Icons.person_add), labelText: 'Enter Group Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter group name';
                }
                return null;
              },
            ),
            TextFormField(
              initialValue: this.widget.data["group"].description,
              decoration: const InputDecoration(
                  icon: Icon(Icons.text_snippet),
                  labelText: 'Enter Group Description'),
              validator: (value) {
                if (value == null) {
                  return 'Please enter description';
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
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Builder(
              builder: (context) => IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back))),
          title: Text(this.widget.data["group"].groupId == ""
              ? "Create Group"
              : "Group Settings"),
          actions: [
            IconButton(
                onPressed: () => _addMembers(), icon: Icon(Icons.person_add))
          ],
        ),
        body:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            CircleAvatar(
              foregroundImage: this.widget.data["group"].image == null
                  ? null
                  : NetworkImage('${this.widget.data["group"].image}'),
              backgroundImage: AssetImage('assets/no-profile.png'),
              radius: 80,
            ),
            Padding(
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child: ElevatedButton(
                  onPressed: () => {}, child: Text("Upload Icon")),
            ),
            _createForm()
          ]),
          Row()
        ]));
  }
}
