import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yaroom/blocs/activeStatus.dart';
import 'package:yaroom/blocs/chatMeta.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:yaroom/blocs/roomMetadata.dart';
import '../blocs/fcmToken.dart';
import '../utils/messageExchange.dart';
import '../utils/authorizationService.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/fcmToken.dart';
import '../utils/fetchBackendData.dart';
import '../blocs/groupMetadata.dart';
import '../utils/types.dart';
import 'dart:async';
import 'package:yaroom/blocs/groupMetadata.dart';
import 'package:yaroom/blocs/friendRequestsData.dart';
import 'package:yaroom/blocs/fcmToken.dart';
import 'package:yaroom/utils/messageExchange.dart';
import 'package:yaroom/utils/types.dart';

class LandingViewModel extends ChangeNotifier {
  bool _signingIn = false;
  bool _signedIn = false;
  bool get signingIn => _signingIn;
  set signingIn(bool b) => _signingIn = b;
  bool get signedIn => _signedIn;
  set signedIn(bool b) => _signedIn = b;
  final AuthorizationService authorizationService;
  LandingViewModel(this.authorizationService);
  Future<bool> signIn() async {
    try {
      _signingIn = true;
      notifyListeners();
      _signedIn = await authorizationService.authorize();
    } catch (e) {
      _signingIn = false;
      notifyListeners();
    } finally {
      _signingIn = false;
      notifyListeners();
    }
    return _signedIn;
  }
}

class LandingPage extends StatelessWidget {
  static const String route = '/signin';
  final LandingViewModel viewModel;
  const LandingPage(this.viewModel);
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image(image: AssetImage('assets/yaroom_full_logo_200x200.png')),
            viewModel.signingIn || viewModel.signedIn
                ? LoadingBar
                : ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            Theme.of(context).primaryColor)),
                    onPressed: () async {
                      await signIn(context);
                    },
                    child: const Text('Login with Auth0'),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> signIn(BuildContext context) async {
    bool signedIn = await viewModel.signIn();
    if (signedIn) {
      final String? accessToken =
          await Provider.of<AuthorizationService>(context, listen: false)
              .getValidAccessToken();
      final userid =
          await Provider.of<AuthorizationService>(context, listen: false)
              .getUserId();
      final String name =
          await Provider.of<AuthorizationService>(context, listen: false)
              .getName();
      await Provider.of<AppDb>(context, listen: false).deleteAll();
      await Provider.of<AppDb>(context, listen: false).createAll();
      // Backend hanldes user new case :)
      // visit route `getUserDetails`
      await fetchUserDetails(accessToken!, name, context);
      // This must be before fetch is calleed
      Map<String, String> lastMsgRead = Map();
      try {
        var response = await http.get(Uri.parse('$BACKEND_URL/v1/lastRead'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': "Bearer $accessToken",
            });
        print("Last read response ${response.statusCode} ${response.body}");
        List<dynamic> result = jsonDecode(response.body);
        result.forEach((mp) {
          lastMsgRead[mp['exchangeId']!] = mp['lastRead']!;
        });
      } catch (e) {
        print("Exception occured while getting last read - $e");
      }
      Provider.of<ChatMetaCubit>(context, listen: false)
          .setUser(userid, lastMsgRead);
      await Future.delayed(Duration(seconds: 2), () async {
        var groups = await RepositoryProvider.of<AppDb>(context, listen: false)
            .getGroupsMetadata()
            .get();
        for (var group in groups) {
          var groupMembers =
              await RepositoryProvider.of<AppDb>(context, listen: false)
                  .getGroupMembers(groupID: group.groupId)
                  .get();
          var d = GroupMetadata(
              groupId: group.groupId,
              name: group.name,
              description: group.description == null ? "" : group.description!,
              groupMembers: groupMembers);
          Provider.of<GroupMetadataCubit>(context, listen: false).update(d);
          print("added group ${group.groupId} to cubit");
        }
      });
      await Future.delayed(Duration(seconds: 2), () async {
        var rooms = await RepositoryProvider.of<AppDb>(context, listen: false)
            .getRoomsMetadata()
            .get();
        for (var room in rooms) {
          var roomMembers =
              await RepositoryProvider.of<AppDb>(context, listen: false)
                  .getRoomMembers(roomID: room.roomId)
                  .get();
          var roomChannels = new Map<String, String>();
          var channelList =
              await RepositoryProvider.of<AppDb>(context, listen: false)
                  .getChannelsOfRoom(roomID: room.roomId)
                  .get();
          for (var channel in channelList) {
            roomChannels[channel.channelId] = channel.channelName;
          }
          var d = RoomMetadata(
              roomId: room.roomId,
              name: room.name,
              description: room.description == null ? "" : room.description!,
              roomMembers: roomMembers,
              roomChannels: roomChannels);
          Provider.of<RoomMetadataCubit>(context, listen: false).update(d);
          print("added room ${room.roomId} to cubit");
        }
      });
      var friendRequests =
          await RepositoryProvider.of<AppDb>(context, listen: false)
              .getFriendRequests()
              .get();
      for (var friendRequest in friendRequests) {
        var d = FriendRequestData(
            userId: friendRequest.userId,
            name: friendRequest.name,
            about: friendRequest.about == null ? "" : friendRequest.about!,
            status: friendRequest.status == null ? 0 : friendRequest.status!);
        Provider.of<FriendRequestCubit>(context, listen: false).update(d);
        print(
            "added friend request ${friendRequest.name} with status ${friendRequest.status} to the cubit");
      }
      // visit route `getLaterMessages`
      await fetchLaterMessages(accessToken, null, context);
      // Start web socket
      Provider.of<MessageExchangeStream>(context, listen: false)
          .start('ws://localhost:8884/v1/ws', accessToken);
      Provider.of<ActiveStatusMap>(context, listen: false).add(userid);
      Provider.of<ActiveStatusMap>(context, listen: false).update(userid, true);
      // Handle fcm token update
      await notifyFCMToken(
          BlocProvider.of<FcmTokenCubit>(context, listen: false), accessToken);
      await Navigator.of(context).pushReplacementNamed('/');
    }
  }
}
