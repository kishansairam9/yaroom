import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:yaroom/screens/login.dart';
import 'secureStorageService.dart';
import 'package:auth0/auth0.dart';
import 'dart:convert';

Map<String?, dynamic> parseIdToken(String? idToken) {
  final parts = idToken?.split(r'.');
  assert(parts?.length == 3);

  return jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts![1]))));
}

class AuthorizationService {
  static const String clientId = 'L7aNin6XYZtN603FYGEOUQ0yEktThELX';
  static const String domain = 'dev-x6unbtjj.us.auth0.com';
  static const String issuer = 'https://$domain';
  static const String redirectUrl = 'com.auth0.yaroom://login-callback';
  static const String logoutRedirectUrl = 'com.auth0.yaroom://logout-callback';
  final FlutterAppAuth appAuth;
  final SecureStorageService secureStorageService;
  AuthorizationService(
    this.appAuth,
    this.secureStorageService,
  );
  Future<bool> authorize() async {
    try {
      final AuthorizationTokenResponse? response =
          await appAuth.authorizeAndExchangeCode(AuthorizationTokenRequest(
              clientId, redirectUrl,
              issuer: 'https://$domain',
              additionalParameters: {'audience': issuer + '/api/v2/'},
              scopes: ['openid', 'profile', 'offline_access', 'app_metadata']));
      await secureStorageService.saveIdToken(response?.idToken);
      print("sign in ///////////");
      print(response?.accessToken);
      await secureStorageService.saveAccessToken(response?.accessToken);
      await secureStorageService
          .saveAccessTokenExpiresIn(response?.accessTokenExpirationDateTime);
      await secureStorageService.saveRefreshToken(response?.refreshToken);
      return true;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  Future<String> getUserId() async {
    final String? idToken = await secureStorageService.getIdToken();

    while (!(idToken != null && idToken.isNotEmpty)) {
      await Future.delayed(Duration(seconds: 2));
    }
    String userId = parseIdToken(idToken)['https://yaroom.com/userId'];
    return userId;
  }

  Future<String?> getValidAccessToken() async {
    final DateTime? expirationDate =
        await secureStorageService.getAccessTokenExpirationDateTime();
    int? cmp = expirationDate?.compareTo(DateTime.now());
    
    if (cmp != null && cmp > 0) {
      return secureStorageService.getAccessToken();
    }
    return _refreshAccessToken();
  }

  Future<String?> _refreshAccessToken() async {
    final String? refreshToken = await secureStorageService.getRefreshToken();
    print(refreshToken);
    try {
      final TokenResponse? response = await appAuth.token(TokenRequest(
          clientId, redirectUrl,
          issuer: issuer, refreshToken: refreshToken));
      // print("refresh token ///////////");
      // print(response?.accessToken);
      await secureStorageService.saveAccessToken(response?.accessToken);
      await secureStorageService
          .saveAccessTokenExpiresIn(response?.accessTokenExpirationDateTime);
      await secureStorageService.saveRefreshToken(response?.refreshToken);
      return response?.accessToken;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> logout(BuildContext context) async {
    String? accessToken = await secureStorageService.getAccessToken();
    print("Accesss token ---- ");
    print(accessToken);
    String? refreshToken = await secureStorageService.getRefreshToken();
    if (accessToken != null) {
      if (refreshToken != null) {
        var client = Auth0Client(
            clientId: clientId,
            clientSecret: clientId,
            domain: domain,
            connectTimeout: 10000,
            sendTimeout: 10000,
            receiveTimeout: 60000,
            useLoggerInterceptor: true,
            accessToken: accessToken);
        // Auth0 client

        // Revoke previous refresh token
        var params = {'refreshToken': refreshToken};
        client.revoke(params);

        // Logout client
        await client.logout();

        String logoutUrl = issuer + '/v2/logout';
        if (await canLaunch(logoutUrl)) {
          launch(logoutUrl);
        }
      }
    }
    // Delete all tokens
    await this.secureStorageService.deleteAll();
    Provider.of<LandingViewModel>(context, listen: false).signedIn = false;
    Provider.of<LandingViewModel>(context, listen: false).signingIn = false;
  }
}
