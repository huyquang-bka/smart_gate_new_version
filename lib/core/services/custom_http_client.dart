import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clean_store_app/core/configs/api_route.dart';
import 'package:clean_store_app/core/services/auth_service.dart';
import 'package:clean_store_app/core/exceptions/session_expired_exception.dart';

class CustomHttpClient {
  Auth? _auth;
  late Future<void> _initialization;
  static const int _timeoutDuration = 5;

  CustomHttpClient() {
    _initialization = _loadAuth();
  }

  Future<void> _loadAuth() async {
    _auth = await AuthService.getAuth();
  }

  Future<http.Response> get(String endpoint) async {
    await _initialization;
    final response = await _getRequestWithToken(endpoint);
    if (response.statusCode == 401 || response.statusCode == 500) {
      final refreshSuccess = await _refreshToken();
      if (refreshSuccess) {
        return _getRequestWithToken(endpoint);
      }
      throw SessionExpiredException();
    }
    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    await _initialization;
    final response = await _postRequestWithToken(endpoint, body);
    if (response.statusCode == 401 || response.statusCode == 500) {
      final refreshSuccess = await _refreshToken();
      if (refreshSuccess) {
        return _postRequestWithToken(endpoint, body);
      }
      throw SessionExpiredException();
    }
    return response;
  }

  Future<http.Response> _getRequestWithToken(String endpoint) {
    final url = Uri.parse(endpoint);
    return http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${_auth?.accessToken ?? ''}',
      },
    ).timeout(const Duration(seconds: _timeoutDuration));
  }

  Future<http.Response> _postRequestWithToken(
      String endpoint, Map<String, dynamic> body) {
    final url = Uri.parse(endpoint);
    return http.post(
      url,
      body: jsonEncode(body),
      headers: {
        'Authorization': 'Bearer ${_auth?.accessToken ?? ''}',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: _timeoutDuration));
  }

  Future<bool> _refreshToken() async {
    try {
      final url = Uri.parse(Url.auth);
      final payload = AuthBody.refreshToken(
        refreshToken: _auth?.refreshToken ?? '',
      );

      final response = await http.post(
        url,
        body: jsonEncode(payload),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _auth = Auth(
          accessToken: body['access_token'],
          refreshToken: body['refresh_token'],
          username: _auth?.username ?? '',
          fullName: body['fullName'],
          userId: body['userId'] ?? -1,
          compId: body['comId'] ?? -1,
        );
        await AuthService.saveAuth(_auth!);
        return true;
      }
    } catch (e) {
      print('Refresh token error: $e');
    }
    return false;
  }

  Future<int> login(String username, String password) async {
    final url = Uri.parse(Url.auth);
    print('Login URL: ${url.toString()}');

    Map<String, String> payload = Map.from(AuthBody.login(
      username: username,
      password: password,
    ));

    try {
      print('Sending login request...');
      final response = await http.post(
        url,
        body: jsonEncode(payload),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _auth = Auth(
          accessToken: body['access_token'],
          refreshToken: body['refresh_token'],
          username: username,
          fullName: body['fullName'],
          userId: body['userId'] ?? -1,
          compId: body['comId'] ?? -1,
        );
        await AuthService.saveAuth(_auth!);
      }
      return response.statusCode;
    } catch (e) {
      print("Login error: $e");
      return 500;
    }
  }
}

// Global instance
final customHttpClient = CustomHttpClient();
