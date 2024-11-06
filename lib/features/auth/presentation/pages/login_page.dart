import 'package:clean_store_app/core/configs/app_constants.dart';
import 'package:clean_store_app/core/configs/app_theme.dart';
import 'package:clean_store_app/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clean_store_app/core/services/custom_http_client.dart';
import 'package:clean_store_app/core/routes/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final credentials = await StorageService.getLoginCredentials();
      print('Credentials: $credentials');
      if (mounted) {
        setState(() {
          _rememberMe = credentials['rememberMe'];
          if (_rememberMe) {
            _usernameController.text = credentials['username'];
            _passwordController.text = credentials['password'];
          }
        });
      }
      print(
          'Loaded credentials - Remember Me: $_rememberMe, Username: ${credentials['username']}'); // Debug print
    } catch (e) {
      print('Error loading credentials: $e'); // Debug print
    }
  }

  Future<void> _handleLogin() async {
    _unfocusAll();

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Save credentials before login attempt if remember me is checked
      if (_rememberMe) {
        await StorageService.saveLoginCredentials(
          username: _usernameController.text,
          password: _passwordController.text,
          rememberMe: true,
        );
        print(
            'Saved credentials - Username: ${_usernameController.text}'); // Debug print
      } else {
        await StorageService.clearLoginCredentials();
        print('Cleared credentials'); // Debug print
      }

      final statusCode = await customHttpClient.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (!mounted) return;
      Navigator.pop(context); // Remove loading indicator

      if (statusCode == 200) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(Routes.main);
        }
      } else {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Login Failed'),
              ],
            ),
            content: const Text("Login failed. Please try again."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading indicator
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Network Error'),
              ],
            ),
            content: const Text('Network error. Please check your connection.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      print('Login error: $e'); // Debug print
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: AppConstants.adminEmail,
      queryParameters: {
        'subject': 'Request for Account Access - ${AppConstants.appName}',
      },
    );

    if (!await launchUrl(emailLaunchUri)) {
      throw Exception('Could not launch email');
    }
  }

  void _unfocusAll() {
    _usernameFocus.unfocus();
    _passwordFocus.unfocus();
  }

  @override
  void dispose() {
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _unfocusAll,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: MediaQuery.of(context).padding.top,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 400,
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.store,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Project name
                    Text(
                      AppConstants.appName,
                      style: AppTheme.headlineMedium.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Username field
                    TextField(
                      controller: _usernameController,
                      focusNode: _usernameFocus,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter your username',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocus);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Password field
                    TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: !_isPasswordVisible,
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 16),
                    // Remember me checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });
                          },
                          child: const Text(
                            'Remember me',
                            style: TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Login button
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withBlue(255),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Contact admin text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account yet? ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: _launchEmail,
                          child: const Text(
                            'Contact admin',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
