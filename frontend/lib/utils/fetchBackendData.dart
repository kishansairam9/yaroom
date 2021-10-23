import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:yaroom/blocs/chatMeta.dart';
import 'package:yaroom/moor/db.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'types.dart';
import 'package:yaroom/moor/utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> populateUserData(data, context) async {
  var userData = data['UserData'];
  var groupsData = data['GroupData'];
  var roomsData = data['RoomData'];
  var usersList = data["Users"];
  var userIdList = [];
  await RepositoryProvider.of<AppDb>(context, listen: false)
      .addUser(userId: userData['Userid'], name: userData['Name']);

  userIdList.add(userData["Userid"]);

  if (usersList != null) {
    for (var user in usersList) {
      if (!userIdList.contains(user["userId"])) {
        userIdList.add(user["userId"]);
        await RepositoryProvider.of<AppDb>(context, listen: false)
            .addUser(userId: user['userId'], name: user['name']);
      }
    }
  }

  if (userData['Pendinglist'] != null) {
    for (var user in userData['Pendinglist']) {
      await RepositoryProvider.of<AppDb>(context, listen: false)
          .addNewFriendRequest(userId: user, status: 1);
    }
  }

  if (userData['Friendslist'] != null) {
    for (var user in userData['Friendslist']) {
      await RepositoryProvider.of<AppDb>(context, listen: false)
          .addNewFriendRequest(userId: user, status: 2);
    }
  }

  if (groupsData != null) {
    for (var groupData in groupsData) {
      if (groupData != null) {
        await RepositoryProvider.of<AppDb>(context, listen: false).createGroup(
          groupId: groupData['Groupid'],
          name: groupData['Name'],
          description: (groupData['Description'] == null
              ? null
              : groupData['Description']),
        );
        if (groupData['Userslist'] != null) {
          for (var user in groupData['Userslist']) {
            if (!userIdList.contains(user['userId'])) {
              await RepositoryProvider.of<AppDb>(context, listen: false)
                  .addUser(userId: user['userId'], name: user['name']);
              userIdList.add(user['userId']);
            }
            await RepositoryProvider.of<AppDb>(context, listen: false)
                .addUserToGroup(
                    groupId: groupData['Groupid'], userId: user['userId']);
          }
        }
      }
    }
  }

  if (roomsData != null) {
    for (var room in roomsData) {
      if (room != null) {
        await RepositoryProvider.of<AppDb>(context, listen: false).createRoom(
          roomId: room['Roomid'],
          name: room['Name'],
          description:
              (room['Description'] == null ? null : room['Description']),
        );
        if (room['Userslist'] != null) {
          for (var user in room['Userslist']) {
            if (!userIdList.contains(user['userId'])) {
              await RepositoryProvider.of<AppDb>(context, listen: false)
                  .addUser(userId: user['userId'], name: user['name']);
              userIdList.add(user['userId']);
            }
            await RepositoryProvider.of<AppDb>(context, listen: false)
                .addUserToRoom(roomsId: room['Roomid'], userId: user['userId']);
          }
        }
        if (room['Channelslist'] != null) {
          for (var k in room['Channelslist'].keys){
            await RepositoryProvider.of<AppDb>(context, listen: false)
                  .addChannelsToRoom(
                      roomId: room['Roomid'], channelId: k, channelName: room['Channelslist'][k]);
          }
        }
      }
    }
  }
}

Future<void> fetchUserDetails(
    String accessToken, String name, BuildContext context) async {
  try {
    var response = await http.get(
        Uri.parse('http://localhost:8884/v1/getUserDetails?name=$name'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        });
    var result = jsonDecode(response.body);
    populateUserData(result, context);
    print("User Details response ${response.statusCode} ${response.body}");
  } catch (e) {
    print("Exception occured while getting user details - $e");
  }
}

Future<void> fetchLaterMessages(
    String accessToken, String? msgId, BuildContext context) async {
  try {
    var response = await http.get(
        Uri.parse('http://localhost:8884/v1/getLaterMessages?lastMsgId=$msgId'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        });

    if (response.body == "null") {
      return;
    }
    if (response.body
        .contains(new RegExp("{\"error\"", caseSensitive: false))) {
      print("Server error, report to support");
      return;
    }
    List<dynamic> results = jsonDecode(response.body);
    results.sort((a, b) => a['msgId'].compareTo(b['msgId']));
    for (var message in results) {
      updateDb(
        RepositoryProvider.of<AppDb>(context, listen: false),
        message,
        Provider.of<ChatMetaCubit>(context, listen: false),
      );
    }
    print("User Details response ${response.statusCode} ${response.body}");
  } catch (e) {
    print("Exception occured while fetching user messages - $e");
  }
}
