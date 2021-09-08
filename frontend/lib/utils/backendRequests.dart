import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:yaroom/moor/db.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'types.dart';
import 'package:yaroom/moor/utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<dynamic> editGroup(dynamic obj, String accessToken) async {
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
