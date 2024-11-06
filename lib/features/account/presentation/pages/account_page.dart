import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clean_store_app/core/services/auth_service.dart';
import 'package:clean_store_app/core/routes/routes.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Auth>(
            future: AuthService.getAuth(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Error loading profile'));
              }

              final auth = snapshot.data!;

              return Column(
                children: [
                  // Profile information section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(auth.fullName),
                            subtitle: Text('User ID: ${auth.userId}'),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.business),
                            title: const Text('Company ID'),
                            subtitle: Text('${auth.compId}'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text('Username'),
                            subtitle: Text(auth.username),
                          ),
                          ListTile(
                            leading: const Icon(Icons.badge),
                            title: const Text('Full Name'),
                            subtitle: Text(auth.fullName),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Show confirmation dialog
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content:
                                const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Logout',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == true) {
                          // Clear auth data
                          await AuthService.clearAuth();

                          if (context.mounted) {
                            Navigator.of(context)
                                .pushReplacementNamed(Routes.login);
                          }
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }
}
