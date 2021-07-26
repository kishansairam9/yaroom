import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'utils/authorizationService.dart';

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
      await Navigator.of(context).pushNamed('/');
    }
  }
}
