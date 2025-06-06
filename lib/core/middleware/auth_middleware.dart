import 'package:smart_gate_new_version/core/routes/routes.dart';
import 'package:smart_gate_new_version/core/services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthMiddleware {
  static Future<String> checkAuthAndGetInitialRoute() async {
    try {
      final auth = await AuthService.getAuth();
      // Check if user has valid auth token
      if (auth.accessToken.isNotEmpty) {
        return Routes.main;
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
    }
    return Routes.login;
  }
}
