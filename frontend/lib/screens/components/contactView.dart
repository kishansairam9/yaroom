import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/types.dart';
import 'package:provider/provider.dart';

class ViewContact extends StatefulWidget {
  final contactData;
  ViewContact(this.contactData);

  @override
  _ViewContactState createState() => _ViewContactState();
}

class _ViewContactState extends State<ViewContact> {
  int status = 5;
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            CircleAvatar(
              foregroundImage: iconImageWrapper(this.widget.contactData.userId),
              radius: 80,
            ),
            Padding(padding: EdgeInsets.only(top: 10, bottom: 10)),
            Text('${this.widget.contactData.name}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  IconButton(
                    onPressed: () => {},
                    icon: Icon(Icons.call),
                    tooltip: "Call",
                  ),
                  Text("Call")
                ],
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () => {},
                    icon: Icon(Icons.video_call_sharp),
                    tooltip: "Video Call",
                  ),
                  Text("Video")
                ],
              ),
              Column(
                children: [
                  IconButton(
                      onPressed: () => Navigator.of(context).pushNamed('/chat',
                          arguments: ChatPageArguments(
                              userId: this.widget.contactData.userId,
                              name: this.widget.contactData.name)),
                      icon: Icon(Icons.message_rounded)),
                  Text("Message")
                ],
              ),
            ],
          ),
          FutureBuilder(
              future: RepositoryProvider.of<AppDb>(context, listen: false)
                  .getFriendStatus(userId: this.widget.contactData.userId)
                  .get(),
              builder: (context, AsyncSnapshot<List<int>> snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.isNotEmpty) {
                    status = snapshot.data![0];
                  }
                  return Card(
                      margin: EdgeInsets.all(20),
                      child: Column(children: [
                        ListTile(
                          leading: Icon(
                            Icons.volume_mute,
                          ),
                          title: Text(
                            "Mute",
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.block,
                            color: Colors.red,
                          ),
                          title: Text(
                            "Block",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        (status == 2)
                            ? ListTile(
                                leading: Icon(
                                  Icons.person_remove_alt_1,
                                  color: Colors.red,
                                ),
                                onTap: () async {
                                  // Backend Request to remove friend
                                  await RepositoryProvider.of<AppDb>(context,
                                          listen: false)
                                      .updateFriendRequest(
                                          status: 3,
                                          userId:
                                              this.widget.contactData.userId);
                                  setState(() {
                                    status = 3;
                                  });
                                },
                                title: Text("Remove Friend",
                                    style: TextStyle(color: Colors.red)),
                              )
                            : ((status == 1) || (status == 4))
                                ? ListTile(
                                    leading: Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                    ),
                                    onTap: null,
                                    title: Text("Pending Request",
                                        style: TextStyle(color: Colors.grey)),
                                  )
                                : ListTile(
                                    leading: Icon(
                                      Icons.person_add_alt,
                                      color: Colors.green,
                                    ),
                                    onTap: () async {
                                      setState(() {
                                        status = 4;
                                      });
                                      if (snapshot.data!.isNotEmpty) {
                                        await RepositoryProvider.of<AppDb>(
                                                context,
                                                listen: false)
                                            .updateFriendRequest(
                                                status: 4,
                                                userId: this
                                                    .widget
                                                    .contactData
                                                    .userId);
                                      } else {
                                        await RepositoryProvider.of<AppDb>(
                                                context,
                                                listen: false)
                                            .addNewFriendRequest(
                                                status: 4,
                                                userId: this
                                                    .widget
                                                    .contactData
                                                    .userId);
                                      }
                                      // Backend Request to add friend i.e add this user to pending list of respective user.
                                    },
                                    title: Text("Add Friend",
                                        style: TextStyle(color: Colors.green)),
                                  ),
                        // ListTile(
                        //   leading: Icon(
                        //     Icons.person_remove_alt_1,
                        //     color: Colors.red,
                        //   ),
                        //   title: (status == 2)? Text(
                        //     "Remove Friend",
                        //     style: TextStyle(color: Colors.red)) : (status == 1)? Text(
                        //     "Request Pending",
                        //     style: TextStyle(color: Colors.red)) : Text(
                        //     "Add Friend",
                        //     style: TextStyle(color: Colors.green),
                        //   ),
                        // ),
                      ]));
                } else if (snapshot.hasError) {
                  print(snapshot.error);
                  return SnackBar(
                      content: Text('Error has occured while reading from DB'));
                }
                return Container();
              }),
        ],
      ),
    );
  }
}
