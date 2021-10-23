import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yaroom/blocs/activeStatus.dart';
import 'package:yaroom/blocs/chatMeta.dart';
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
                ? CircularProgressIndicator()
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
      // This must be before fetch is calleed
      Provider.of<ChatMetaCubit>(context, listen: false).setUser(userid);
      // Backend hanldes user new case :)
      // visit route `getUserDetails`
      await fetchUserDetails(accessToken!, name, context);
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
          var ChannelList =
              await RepositoryProvider.of<AppDb>(context, listen: false)
                  .getChannelsOfRoom(roomID: room.roomId)
                  .get();
          for (var channel in ChannelList) {
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
