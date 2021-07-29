import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../blocs/fcmToken.dart';
import '../utils/messageExchange.dart';
import '../utils/authorizationService.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/fcmToken.dart';

class LandingViewModel extends ChangeNotifier {
  bool _signingIn = false;
  bool _signedIn = false;
  bool get signingIn => _signingIn;
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
            if (viewModel.signingIn) CircularProgressIndicator(),
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      Theme.of(context).primaryColor)),
              onPressed: viewModel.signingIn
                  ? null
                  : () async {
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

      // Start web socket
      Provider.of<MessageExchangeStream>(context, listen: false)
          .start('ws://localhost:8884/v1/ws', accessToken!);

      // Handle fcm token update
      await notifyFCMToken(
          BlocProvider.of<FcmTokenCubit>(context, listen: false), accessToken);
      await Navigator.of(context).pushReplacementNamed('/');
    }
  }
}
