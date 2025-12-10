import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_gate_new_version/core/configs/app_theme.dart';
import 'package:smart_gate_new_version/core/routes/routes.dart';
import 'package:smart_gate_new_version/core/services/auth_service.dart';
import 'package:smart_gate_new_version/core/services/root_check_service.dart';

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
    final bool isRooted = await rootCheckService.isDeviceRooted();
    if (!mounted) return;
    if (isRooted) {
      await _showRootedDeviceDialog();
      if (mounted) {
        SystemNavigator.pop();
      }
      return;
    }
    try {
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

  Future<void> _showRootedDeviceDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _RootedDeviceDialog(),
    );
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

class _RootedDeviceDialog extends StatelessWidget {
  const _RootedDeviceDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unsupported Device'),
      content: const Text(
        'This device appears to be rooted. For security reasons the application will close.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
