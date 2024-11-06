class AppKey {
  static const String _prefix = 'smart_gate_';

  // Auth Keys
  static const String authData = '${_prefix}auth_data';

  // Login Credentials Keys
  static const String rememberMe = '${_prefix}remember_me';
  static const String savedUsername = '${_prefix}saved_username';
  static const String savedPassword = '${_prefix}saved_password';

  // Settings Keys
  static const String theme = '${_prefix}theme_mode';
  static const String language = '${_prefix}language';

  // User Preferences Keys
  static const String notifications = '${_prefix}notifications_enabled';
  static const String biometrics = '${_prefix}biometrics_enabled';

  // Cache Keys
  static const String lastSync = '${_prefix}last_sync_time';
  static const String cacheExpiry = '${_prefix}cache_expiry';
}
