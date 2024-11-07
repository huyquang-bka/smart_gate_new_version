import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_gate_new_version/core/configs/app_key.dart';

class Auth {
  String accessToken;
  String refreshToken;
  String username;
  String fullName;
  int userId;
  int compId;

  Auth({
    required this.accessToken,
    required this.refreshToken,
    required this.username,
    required this.fullName,
    required this.userId,
    required this.compId,
  });

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'username': username,
        'fullName': fullName,
        'userId': userId,
        'compId': compId,
      };

  factory Auth.fromJson(Map<String, dynamic> json) => Auth(
        accessToken: json['accessToken'],
        refreshToken: json['refreshToken'],
        username: json['username'],
        fullName: json['fullName'],
        userId: json['userId'] as int,
        compId: json['compId'] as int,
      );
}

class AuthService {
  static Future<void> saveAuth(Auth auth) async {
    final prefs = await SharedPreferences.getInstance();
    final authJson = jsonEncode(auth.toJson());
    await prefs.setString(AppKey.authData, authJson);
  }

  static Future<Auth> getAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final authJson = prefs.getString(AppKey.authData);
    if (authJson == null) {
      return Auth(
        accessToken: "",
        refreshToken: "",
        username: "",
        fullName: "",
        userId: -1,
        compId: -1,
      );
    }
    return Auth.fromJson(jsonDecode(authJson));
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppKey.authData);
  }
}
