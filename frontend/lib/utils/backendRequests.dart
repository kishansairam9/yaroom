import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'authorizationService.dart';
import 'dart:convert';
import 'types.dart';

Future<dynamic> editUser(dynamic obj, BuildContext context) async {
  String? accessToken =
      await Provider.of<AuthorizationService>(context, listen: false)
          .getValidAccessToken();
  if (accessToken == null) {
    return Future.value('/signin');
  }
  try {
    var response = await http.post(
        Uri.parse('http://localhost:8884/v1/editUserDetails'),
        body: obj,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        });
    print("user edit response ${response.statusCode} ${response.body}");
    return response.body;
  } catch (e) {
    print("Exception occured in user create/edit $e");
    return null;
  }
}

Future<dynamic> editGroup(dynamic obj, BuildContext context) async {
  String? accessToken =
      await Provider.of<AuthorizationService>(context, listen: false)
          .getValidAccessToken();
  if (accessToken == null) {
    return Future.value('/signin');
  }
  try {
    var response = await http.post(
        Uri.parse('http://localhost:8884/v1/editGroupDetails'),
        body: obj,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        });
    print("Group edit response ${response.statusCode} ${response.body}");
    if (response.statusCode == 200) return response.body;
    throw response.body;
  } catch (e) {
    print("Exception occured in group create/edit $e");
    return null;
  }
}

Future<dynamic> exitGroup(String groupId, BuildContext context) async {
  String? accessToken =
      await Provider.of<AuthorizationService>(context, listen: false)
          .getValidAccessToken();
  if (accessToken == null) {
    return Future.value('/signin');
  }
  try {
    var response =
        await http.post(Uri.parse('http://localhost:8884/v1/exitGroup'),
            body: jsonEncode(<String, dynamic>{
              "groupId": groupId,
              "user": [Provider.of<UserId>(context, listen: false)]
            }),
            headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        });
    print("Group exit response ${response.statusCode} ${response.body}");
    return response.body;
  } catch (e) {
    print("Exception occured while exiting user from group $e");
    return null;
  }
}

Future<dynamic> friendRequest(
    String userId, int status, BuildContext context) async {
  String? accessToken =
      await Provider.of<AuthorizationService>(context, listen: false)
          .getValidAccessToken();
  if (accessToken == null) {
    return Future.value('/signin');
  }
  try {
    var response = await http.post(
        Uri.parse('http://localhost:8884/v1/friendRequest'),
        body: jsonEncode(
            <String, String>{"userId": userId, "status": status.toString()}),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        });
    print("friend request response ${response.statusCode} ${response.body}");
    return response.body;
  } catch (e) {
    print("Exception occured changing friend status $e");
    return null;
  }
}
