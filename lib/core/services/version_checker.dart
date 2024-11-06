import 'package:clean_store_app/core/configs/api_route.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionChecker {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // Get current version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Get latest version from GitHub
      final response = await http.get(Uri.parse(Url.versionChecker));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name'].toString().replaceAll('v', '');
        final downloadUrl = data['assets'][0]['browser_download_url'];

        // Compare versions
        if (_shouldUpdate(currentVersion, latestVersion)) {
          if (!context.mounted) return;
          _showUpdateDialog(context, latestVersion, downloadUrl);
        }
      }
    } catch (e) {
      debugPrint('Version check error: $e');
    }
  }

  static bool _shouldUpdate(String currentVersion, String latestVersion) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> latest = latestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (latest[i] > current[i]) return true;
      if (latest[i] < current[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
    BuildContext context,
    String newVersion,
    String downloadUrl,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.blue),
            SizedBox(width: 8),
            Text('Update Available'),
          ],
        ),
        content: Text(
          'A new version ($newVersion) is available. Would you like to update?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final url = Uri.parse(downloadUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            child: const Text(
              'Update',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
