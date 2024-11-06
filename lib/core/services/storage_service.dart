import 'package:shared_preferences/shared_preferences.dart';
import 'package:clean_store_app/core/configs/app_key.dart';

class StorageService {
  static Future<void> saveLoginCredentials({
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppKey.rememberMe, rememberMe);
      if (rememberMe) {
        await prefs.setString(AppKey.savedUsername, username);
        await prefs.setString(AppKey.savedPassword, password);
        print('Credentials saved successfully'); // Debug print
      } else {
        await clearLoginCredentials();
      }
    } catch (e) {
      print('Error saving credentials: $e'); // Debug print
    }
  }

  static Future<Map<String, dynamic>> getLoginCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(AppKey.rememberMe) ?? false;
      final username = prefs.getString(AppKey.savedUsername) ?? '';
      final password = prefs.getString(AppKey.savedPassword) ?? '';

      print('Retrieved credentials - Remember Me: $rememberMe, Has Username: ${username.isNotEmpty}'); // Debug print

      return {
        'rememberMe': rememberMe,
        'username': username,
        'password': password,
      };
    } catch (e) {
      print('Error getting credentials: $e'); // Debug print
      return {
        'rememberMe': false,
        'username': '',
        'password': '',
      };
    }
  }

  static Future<void> clearLoginCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppKey.rememberMe);
      await prefs.remove(AppKey.savedUsername);
      await prefs.remove(AppKey.savedPassword);
      print('Credentials cleared successfully'); // Debug print
    } catch (e) {
      print('Error clearing credentials: $e'); // Debug print
    }
  }
}
