import 'package:clean_store_app/core/configs/app_constants.dart';
import 'package:clean_store_app/core/configs/app_theme.dart';
import 'package:clean_store_app/core/middleware/auth_middleware_page.dart';
import 'package:clean_store_app/core/providers/app_settings_provider.dart';
import 'package:clean_store_app/core/routes/routes.dart';
import 'package:clean_store_app/features/auth/presentation/pages/login_page.dart';
import 'package:clean_store_app/features/main/presentation/pages/main_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: language.locale,
      initialRoute: Routes.initial,
      routes: {
        Routes.initial: (context) => const AuthMiddlewarePage(),
        Routes.login: (context) => const LoginPage(),
        Routes.main: (context) => const MainPage(),
      },
    );
  }
}
