import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english(Locale('en'), 'English', '🇺🇸'),
  vietnamese(Locale('vi'), 'Tiếng Việt', '🇻🇳');

  final Locale locale;
  final String name;
  final String flag;

  const AppLanguage(this.locale, this.name, this.flag);
}

class LanguageProvider extends ChangeNotifier {
  static const String _key = 'smart_gate_language';
  AppLanguage _currentLanguage = AppLanguage.english;

  AppLanguage get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_key);
      if (languageCode != null) {
        final savedLanguage = AppLanguage.values.firstWhere(
          (l) => l.locale.languageCode == languageCode,
          orElse: () => AppLanguage.english,
        );
        _currentLanguage = savedLanguage;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, language.locale.languageCode);
      _currentLanguage = language;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }
}
