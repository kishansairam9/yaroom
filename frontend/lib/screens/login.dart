import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yaroom/blocs/activeStatus.dart';
import '../blocs/fcmToken.dart';
import '../utils/messageExchange.dart';
import '../utils/authorizationService.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/fcmToken.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/fetchBackendData.dart';

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
      final String name =
          await Provider.of<AuthorizationService>(context, listen: false)
              .getName();
      // Backend hanldes user new case :)
      // visit route `getUserDetails`
      await fetchUserDetails(accessToken!, name, context);

      // visit route `getLaterMessages`
      await fetchLaterMessages(accessToken, null, context);

      // Start web socket
      Provider.of<MessageExchangeStream>(context, listen: false)
          .start('ws://localhost:8884/v1/ws', accessToken);
      final userid =
          await Provider.of<AuthorizationService>(context, listen: false)
              .getUserId();
      Provider.of<ActiveStatusMap>(context, listen: false).add(userid);
      Provider.of<ActiveStatusMap>(context, listen: false).update(userid, true);
      // Handle fcm token update
      await notifyFCMToken(
          BlocProvider.of<FcmTokenCubit>(context, listen: false), accessToken);
      await Navigator.of(context).pushReplacementNamed('/');
    }
  }
}
