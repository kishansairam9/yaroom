import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
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
  var userIdList = [];
  await RepositoryProvider.of<AppDb>(context, listen: false)
      .addUser(userId: userData['Userid'], name: userData['Name']);

  userIdList.add(userData['Userid']);

  if (userData['Pendinglist'] != null) {
    for (var req in userData['Pendinglist']) {
      await RepositoryProvider.of<AppDb>(context, listen: false)
          .addNewFriendRequest(userId: req, status: 1);
    }
  }

  if (userData['Friendslist'] != null) {
    for (var req in userData['Friendslist']) {
      await RepositoryProvider.of<AppDb>(context, listen: false)
          .addNewFriendRequest(userId: req, status: 2);
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
          print(groupData['Userslist']);
          for (var user in groupData['Userslist']) {
            if (!userIdList.contains(user['Userid'])) {
              await RepositoryProvider.of<AppDb>(context, listen: false)
                  .addUser(userId: user['Userid'], name: user['Name']);
            }
            await RepositoryProvider.of<AppDb>(context, listen: false)
                .addUserToGroup(
                    groupId: groupData['Groupid'], userId: user['Userid']);
          }
        }
      }
    }
  }

  if (roomsData != null) {
    for (var room in roomsData) {
      await RepositoryProvider.of<AppDb>(context, listen: false).createRoom(
          roomId: room['Roomid'],
          name: room['Name'],
          description: room['Description']);
      if (room['Userslist'] != null) {
        for (var user in room['Userslist']) {
          if (!userIdList.contains(user['Userid'])) {
            await RepositoryProvider.of<AppDb>(context, listen: false)
                .addUser(userId: user['Userid'], name: user['Name']);
          }
          await RepositoryProvider.of<AppDb>(context, listen: false)
              .addUserToRoom(roomsId: room['Roomid'], userId: user['Userid']);
        }
      }
      if (room['Channelslist'] != null) {
        room['Channelslist'].forEach((k, v) async =>
            await RepositoryProvider.of<AppDb>(context, listen: false)
                .addChannelsToRoom(
                    roomId: room['Roomid'], channelId: k, channelName: v));
      }
    }
  }
}

Future<void> fetchUserDetails(String accessToken, BuildContext context) async {
  try {
    var response = await http.get(
        Uri.parse('http://localhost:8884/v1/getUserDetails'),
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
    var results = jsonDecode(response.body);
    for (var message in results) {
      updateDb(RepositoryProvider.of<AppDb>(context, listen: false), message);
    }
    print("User Details response ${response.statusCode} ${response.body}");
  } catch (e) {
    print("Exception occured while fetching user messages - $e");
  }
}
