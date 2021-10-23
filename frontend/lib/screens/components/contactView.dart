import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaroom/blocs/friendRequestsData.dart';
import 'package:yaroom/utils/backendRequests.dart';
import '../../utils/types.dart';
import 'package:provider/provider.dart';

class ViewContact extends StatefulWidget {
  final FriendRequestData contactData;
  ViewContact(this.contactData);

  @override
  _ViewContactState createState() => _ViewContactState();
}

class _ViewContactState extends State<ViewContact> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendRequestCubit, FriendRequestDataMap>(
        bloc: Provider.of<FriendRequestCubit>(context, listen: false),
        builder: (context, state) {
          if (!state.data.containsKey(this.widget.contactData.userId)) {
            Provider.of<FriendRequestCubit>(context, listen: false)
                .update(this.widget.contactData);
          }
          return SingleChildScrollView(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      CircleAvatar(
                        foregroundImage:
                            iconImageWrapper(this.widget.contactData.userId),
                        radius: 60,
                      ),
                      Padding(padding: EdgeInsets.only(top: 10, bottom: 10)),
                      Text(
                          '${state.data[this.widget.contactData.userId]!.name}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20))
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
                            onPressed: () => Navigator.of(context).pushNamed(
                                '/chat',
                                arguments: ChatPageArguments(
                                    userId: this.widget.contactData.userId,
                                    name: state
                                        .data[this.widget.contactData.userId]!
                                        .name)),
                            icon: Icon(Icons.message_rounded)),
                        Text("Message")
                      ],
                    ),
                  ],
                ),
                Card(
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
                      (state.data[this.widget.contactData.userId]!.status ==
                              FriendRequestType.friend.index)
                          ? ListTile(
                              leading: Icon(
                                Icons.person_remove_alt_1,
                                color: Colors.red,
                              ),
                              onTap: () async {
                                // Backend Request to remove friend
                                await friendRequest(
                                    this.widget.contactData.userId,
                                    FriendRequestType.removeFriend.index,
                                    context);
                                await RepositoryProvider.of<AppDb>(context,
                                        listen: false)
                                    .updateFriendRequest(
                                        status: FriendRequestType
                                            .removeFriend.index,
                                        userId: this.widget.contactData.userId);
                                this.widget.contactData.status =
                                    FriendRequestType.removeFriend.index;
                                Provider.of<FriendRequestCubit>(context,
                                        listen: false)
                                    .update(this.widget.contactData);
                                print("Friend Request Cubit updated");
                                print(this.widget.contactData);
                                // setState(() {
                                //   status =
                                //       FriendRequestType.removeFriend.index;
                                // });
                              },
                              title: Text("Remove Friend",
                                  style: TextStyle(color: Colors.red)),
                            )
                          : ((this.widget.contactData.status ==
                                      FriendRequestType.pending.index) ||
                                  (this.widget.contactData.status == 5))
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
                                    // setState(() {
                                    //   status = 5;
                                    // });
                                    await friendRequest(
                                        this.widget.contactData.userId,
                                        FriendRequestType.pending.index,
                                        context);
                                    if (state
                                            .data[
                                                this.widget.contactData.userId]!
                                            .status !=
                                        -1) {
                                      await RepositoryProvider.of<AppDb>(
                                              context,
                                              listen: false)
                                          .updateFriendRequest(
                                              status: 5,
                                              userId: this
                                                  .widget
                                                  .contactData
                                                  .userId);
                                      this.widget.contactData.status = 5;
                                      Provider.of<FriendRequestCubit>(context,
                                              listen: false)
                                          .update(this.widget.contactData);
                                    } else {
                                      await RepositoryProvider.of<AppDb>(
                                              context,
                                              listen: false)
                                          .addNewFriendRequest(
                                              status: 5,
                                              userId: this
                                                  .widget
                                                  .contactData
                                                  .userId);
                                      this.widget.contactData.status = 5;
                                      Provider.of<FriendRequestCubit>(context,
                                              listen: false)
                                          .update(this.widget.contactData);
                                    }
                                  },
                                  title: Text("Add Friend",
                                      style: TextStyle(color: Colors.green)),
                                ),
                    ]))
              ]));
        });
  }
}
