import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_gate_new_version/core/configs/api_route.dart';
import 'package:smart_gate_new_version/core/configs/app_constants.dart';
import 'package:smart_gate_new_version/core/services/auth_service.dart';
import 'package:smart_gate_new_version/core/routes/routes.dart';
import 'package:smart_gate_new_version/core/services/custom_http_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_gate_new_version/core/providers/language_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'package:smart_gate_new_version/core/services/checkpoint_service.dart';
import 'package:smart_gate_new_version/features/seal/domain/models/check_point.dart';
import 'package:smart_gate_new_version/core/widgets/checkpoint_selection_dialog.dart';
import 'package:smart_gate_new_version/features/task/presentation/pages/task_done_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.account),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Stack(
              children: [
                Icon(Icons.task_alt),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(
                    Icons.check_circle,
                    size: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            tooltip: l10n.tasksDone,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TaskDonePage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () async {
              final response = await customHttpClient.get(Url.getCheckPoint);
              if (response.statusCode == 200) {
                final auth = await AuthService.getAuth();
                final List<dynamic> data = json.decode(response.body)["data"];
                final allCheckPoints = data
                    .map((json) => CheckPoint.fromJson(json))
                    .where((checkpoint) => checkpoint.compId == auth.compId)
                    .toList();

                if (context.mounted && allCheckPoints.isNotEmpty) {
                  final selectedIds =
                      await CheckpointService.getSelectedCheckpointIds();
                  await showDialog(
                    context: context,
                    builder: (context) => CheckpointSelectionDialog(
                      checkpoints: allCheckPoints,
                      selectedIds: selectedIds,
                      isCollapsed: false,
                    ),
                  );
                }
              }
            },
          ),
          PopupMenuButton<AppLanguage>(
            icon: Text(languageProvider.currentLanguage.flag),
            onSelected: (AppLanguage language) async {
              await languageProvider.setLanguage(language);
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
          ),
        ],
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
                return Center(child: Text(l10n.errorLoadingAuth));
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
                            subtitle: Text(auth.fullName),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.business),
                            title: Text(l10n.companyIdTitle),
                            subtitle: Text('${auth.compId}'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(l10n.username),
                            subtitle: Text(auth.username),
                          ),
                          ListTile(
                            leading: const Icon(Icons.badge),
                            title: Text(l10n.fullName),
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
                            title: Text(l10n.logout),
                            content: Text(l10n.logoutConfirm),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  l10n.logout,
                                  style: const TextStyle(color: Colors.red),
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
                      label: Text(l10n.logout),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Copyright section
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(AppConstants.companyWebsite);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    child: const Text(
                      AppConstants.copyright,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
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
