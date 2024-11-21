import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:smart_gate_new_version/core/configs/app_constants.dart';
import 'package:smart_gate_new_version/core/configs/app_theme.dart';
import 'package:smart_gate_new_version/core/middleware/auth_middleware_page.dart';
import 'package:smart_gate_new_version/core/providers/language_provider.dart';
import 'package:smart_gate_new_version/core/routes/routes.dart';
import 'package:smart_gate_new_version/core/services/mqtt_service.dart';
import 'package:smart_gate_new_version/features/auth/presentation/pages/login_page.dart';
import 'package:smart_gate_new_version/features/main/presentation/pages/main_page.dart';
import 'package:smart_gate_new_version/features/task/providers/task_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  mqttService.connect();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          locale: languageProvider.currentLanguage.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          initialRoute: Routes.initial,
          routes: {
            Routes.initial: (context) => const AuthMiddlewarePage(),
            Routes.login: (context) => const LoginPage(),
            Routes.main: (context) => const MainPage(),
          },
        );
      },
    );
  }
}
