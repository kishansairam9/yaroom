import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'secureStorageService.dart';
import 'package:auth0/auth0.dart';

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
              scopes: ['openid', 'profile', 'offline_access', 'app_metadata']));
      await secureStorageService.saveIdToken(response?.idToken);
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

  Future<String?> getValidAccessToken() async {
    final DateTime? expirationDate =
        await secureStorageService.getAccessTokenExpirationDateTime();
    int? cmp = expirationDate?.compareTo(DateTime.now());
    if (cmp != null && cmp < 0) {
      return secureStorageService.getAccessToken();
    }
    return _refreshAccessToken();
  }

  Future<String?> _refreshAccessToken() async {
    final String? refreshToken = await secureStorageService.getRefreshToken();
    final TokenResponse? response = await appAuth.token(TokenRequest(
        clientId, redirectUrl,
        issuer: issuer, refreshToken: refreshToken));
    await secureStorageService.saveAccessToken(response?.accessToken);
    await secureStorageService
        .saveAccessTokenExpiresIn(response?.accessTokenExpirationDateTime);
    await secureStorageService.saveRefreshToken(response?.refreshToken);
    return response?.accessToken;
  }

  Future<void> logout(BuildContext context) async {
    String? access_token = await secureStorageService.getAccessToken();
    String? refresh_token = await secureStorageService.getRefreshToken();
    if (access_token != null) {
      if (refresh_token != null) {
        var client = Auth0Client(
            clientId: clientId,
            clientSecret: clientId,
            domain: domain,
            connectTimeout: 10000,
            sendTimeout: 10000,
            receiveTimeout: 60000,
            useLoggerInterceptor: true,
            accessToken: access_token);
        // Auth0 client

        // Revoke previous refresh token
        var params = {'refreshToken': refresh_token};
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
  }
}
