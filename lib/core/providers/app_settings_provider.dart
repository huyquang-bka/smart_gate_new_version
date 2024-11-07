import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  AppLanguage _language = AppLanguage.english;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }
}

enum AppLanguage {
  english(Locale('en', 'US'), 'English', '🇺🇸'),
  vietnamese(Locale('vi', 'VN'), 'Tiếng Việt', '🇻🇳');

  final Locale locale;
  final String name;
  final String flag;

  const AppLanguage(this.locale, this.name, this.flag);
}
