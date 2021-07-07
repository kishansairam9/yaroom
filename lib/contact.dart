import 'package:flutter/material.dart';

class ViewContact extends StatelessWidget {
  final contactData;
  ViewContact(this.contactData);
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            CircleAvatar(
              foregroundImage: NetworkImage('${this.contactData.image}'),
              backgroundImage: AssetImage('assets/no-profile.png'),
              radius: 80,
            ),
            Padding(padding: EdgeInsets.only(top: 10, bottom: 10)),
            Text('${this.contactData.name}',
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
                    onPressed: () => {},
                    icon: Icon(Icons.message),
                    tooltip: "Message",
                  ),
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
                ListTile(
                  leading: Icon(
                    Icons.person_remove_alt_1,
                    color: Colors.red,
                  ),
                  title: Text(
                    "Remove Friend",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ])),
        ],
      ),
    );
  }
}
