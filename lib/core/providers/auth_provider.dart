import 'package:flutter/foundation.dart';
import 'package:smart_gate_new_version/core/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  Auth? _auth;

  Auth? get auth => _auth;

  AuthProvider() {
    checkAuthState();
  }

  Future<void> checkAuthState() async {
    final auth = await AuthService.getAuth();
    if (auth.accessToken.isNotEmpty) {
      _auth = auth;
      notifyListeners();
    }
  }

  void setAuth(Auth auth) {
    _auth = auth;
    notifyListeners();
  }

  void clearAuth() {
    _auth = null;
    notifyListeners();
  }
}
