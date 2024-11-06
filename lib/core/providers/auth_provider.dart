import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clean_store_app/core/services/auth_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, Auth?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<Auth?> {
  AuthNotifier() : super(null) {
    checkAuthState();
  }

  Future<void> checkAuthState() async {
    final auth = await AuthService.getAuth();
    if (auth.accessToken.isNotEmpty) {
      state = auth;
    }
  }

  void setAuth(Auth auth) {
    state = auth;
  }

  void clearAuth() {
    state = null;
  }
} 