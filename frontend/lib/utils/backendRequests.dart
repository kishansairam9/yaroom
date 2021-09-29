import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'authorizationService.dart';

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
    return response.body;
  } catch (e) {
    print("Exception occured in notify fcm token $e");
    return null;
  }
}

Future<dynamic> exitGroup(dynamic obj, BuildContext context) async {
  String? accessToken =
      await Provider.of<AuthorizationService>(context, listen: false)
          .getValidAccessToken();
  if (accessToken == null) {
    return Future.value('/signin');
  }
  try {
    var response = await http.post(
        Uri.parse('http://localhost:8884/v1/exitGroup'),
        body: obj,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        });
    print("Group exit response ${response.statusCode} ${response.body}");
    return response.body;
  } catch (e) {
    print("Exception occured in notify fcm token $e");
    return null;
  }
}

Future<dynamic> friendRequest(dynamic obj, BuildContext context) async {
  String? accessToken =
      await Provider.of<AuthorizationService>(context, listen: false)
          .getValidAccessToken();
  if (accessToken == null) {
    return Future.value('/signin');
  }
  try {
    var response = await http.post(
        Uri.parse('http://localhost:8884/v1/friendRequest'),
        body: obj,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        });
    print("friend request response ${response.statusCode} ${response.body}");
    return response.body;
  } catch (e) {
    print("Exception occured in notify fcm token $e");
    return null;
  }
}
