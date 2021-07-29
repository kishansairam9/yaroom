import 'package:http/http.dart' as http;
import 'package:yaroom/blocs/fcmToken.dart';
import 'dart:convert';

Future<void> notifyFCMToken(
    FcmTokenCubit tokenCubit, String accessToken) async {
  // TODO: REMOVE THIS SENDING OF USER NAME AND IMAGE! SHOULDN'T
  String userName = 'testuser', image = '';
  // Send token
  try {
    var response =
        await http.post(Uri.parse('http://localhost:8884/v1/fcmTokenUpdate'),
            body: jsonEncode(<String, String>{
              'fcm_token': tokenCubit.state,
              'name': userName,
              'image': image,
            }),
            headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        });
    print("Fcm token response ${response.statusCode} ${response.body}");
  } catch (e) {
    print("Exception occured in notify fcm token $e");
  }

  // Listen for updates
  tokenCubit.stream.listen((newToken) async {
    try {
      var response =
          await http.post(Uri.parse('http://localhost:8884/v1/fcmTokenUpdate'),
              body: jsonEncode(<String, String>{
                'fcm_token': newToken,
                'name': userName,
                'image': image,
              }),
              headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': "Bearer $accessToken",
          });
      print("Fcm token response ${response.statusCode} ${response.body}");
    } catch (e) {
      print("Exception occured in fcm notify $e");
    }
  });
}

Future<void> invalidateFCMToken(
    FcmTokenCubit tokenCubit, String accessToken) async {
  // TODO: REMOVE THIS SENDING OF USER NAME AND IMAGE! SHOULDN'T
  String userName = 'testuser', image = '';
  // Send token
  try {
    var response = await http
        .post(Uri.parse('http://localhost:8884/v1/fcmTokenInvalidate'),
            body: jsonEncode(<String, String>{
              'fcm_token': tokenCubit.state,
              'name': userName,
              'image': image,
            }),
            headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        });
    print("Fcm token response ${response.statusCode} ${response.body}");
  } catch (e) {
    print("Exception occured in invalidate fcm token $e");
  }
}
