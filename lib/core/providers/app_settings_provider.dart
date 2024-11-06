import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

enum AppLanguage {
  english(Locale('en', 'US'), 'English', '🇺🇸'),
  vietnamese(Locale('vi', 'VN'), 'Tiếng Việt', '🇻🇳');

  final Locale locale;
  final String name;
  final String flag;

  const AppLanguage(this.locale, this.name, this.flag);
}

final languageProvider = StateProvider<AppLanguage>((ref) => AppLanguage.english); 