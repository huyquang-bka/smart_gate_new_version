import 'package:clean_store_app/core/routes/routes.dart';
import 'package:clean_store_app/core/services/auth_service.dart';
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
    _initializeAndRoute();
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
    return const SizedBox();
  }
}
