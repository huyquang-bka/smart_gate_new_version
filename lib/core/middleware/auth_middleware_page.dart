import 'package:smart_gate_new_version/core/configs/app_theme.dart';
import 'package:smart_gate_new_version/core/routes/routes.dart';
import 'package:smart_gate_new_version/core/services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthMiddlewarePage extends StatefulWidget {
  const AuthMiddlewarePage({super.key});

  @override
  State<AuthMiddlewarePage> createState() => _AuthMiddlewarePageState();
}

class _AuthMiddlewarePageState extends State<AuthMiddlewarePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndRoute();
    });
  }

  Future<void> _initializeAndRoute() async {
    try {
      // Check auth status
      final auth = await AuthService.getAuth();

      if (!mounted) return;

      if (auth.accessToken.isNotEmpty) {
        Navigator.of(context).pushReplacementNamed(Routes.main);
      } else {
        Navigator.of(context).pushReplacementNamed(Routes.login);
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
