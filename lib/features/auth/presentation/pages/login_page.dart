import 'package:smart_gate_new_version/core/configs/app_constants.dart';
import 'package:smart_gate_new_version/core/configs/app_theme.dart';
import 'package:smart_gate_new_version/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_gate_new_version/core/services/custom_http_client.dart';
import 'package:smart_gate_new_version/core/routes/routes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:smart_gate_new_version/core/providers/language_provider.dart';
import 'package:provider/provider.dart';

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
      if (mounted) {
        setState(() {
          _rememberMe = credentials['rememberMe'];
          if (_rememberMe) {
            _usernameController.text = credentials['username'];
            _passwordController.text = credentials['password'];
          }
        });
      }
    } catch (e) {
      print('Error loading credentials: $e'); // Debug print
    }
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
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
            content: Text(l10n.loginFailed),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading indicator
        final l10n = AppLocalizations.of(context)!;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Text(l10n.networkError),
              ],
            ),
            content: Text(l10n.networkError),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok),
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
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLanguage = languageProvider.currentLanguage;

    return GestureDetector(
      onTap: () {
        _usernameFocus.unfocus();
        _passwordFocus.unfocus();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 400,
                      minHeight: size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo and Title
                        Image.asset(
                          'lib/assets/icons/logo/CHP_logo.png',
                          width: 80,
                          height: 80,
                          color: AppTheme.primaryColor,
                          errorBuilder: (context, error, stack) =>
                              const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          AppConstants.appName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Username field
                        TextField(
                          controller: _usernameController,
                          focusNode: _usernameFocus,
                          decoration: InputDecoration(
                            labelText: l10n.username,
                            hintText: l10n.enterUsername,
                            prefixIcon: const Icon(Icons.person),
                            border: const OutlineInputBorder(),
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
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            hintText: l10n.enterPassword,
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
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
                          ),
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
                              onTap: () => setState(() {
                                _rememberMe = !_rememberMe;
                              }),
                              child: Text(l10n.rememberMe),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Login button
                        ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            l10n.login,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contact admin
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l10n.noAccount),
                            TextButton(
                              onPressed: _launchEmail,
                              child: Text(l10n.contactAdmin),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Language selector in top right corner
              Positioned(
                top: 8,
                right: 8,
                child: PopupMenuButton<AppLanguage>(
                  initialValue: currentLanguage,
                  onSelected: (AppLanguage language) {
                    languageProvider.setLanguage(language);
                  },
                  itemBuilder: (BuildContext context) {
                    return AppLanguage.values.map((AppLanguage language) {
                      return PopupMenuItem<AppLanguage>(
                        value: language,
                        child: Row(
                          children: [
                            Text(language.flag),
                            const SizedBox(width: 8),
                            Text(language.name),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(currentLanguage.flag),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
