import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../di/injection.dart';
import '../network/api_client.dart';

class VersionCheckService {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await getIt<ApiClient>().dio.get(
        '${AppConstants.serverUrl}/app-version/check',
        queryParameters: {'currentVersion': AppConstants.appVersion},
      );

      final data = response.data;
      if (data['updateAvailable'] != true) return;

      final forceUpdate = data['forceUpdate'] == true;
      final latestVersion = data['latestVersion'] ?? '';
      final downloadUrl = data['downloadUrl'] ?? '';
      final releaseNotes = data['releaseNotes'] ?? '';

      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: !forceUpdate,
        builder: (ctx) => PopScope(
          canPop: !forceUpdate,
          child: AlertDialog(
            title: const Text('Update Available'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A new version ($latestVersion) is available.'),
                if (releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(releaseNotes,
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
                if (forceUpdate) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'This update is required to continue using the app.',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
                  ),
                ],
              ],
            ),
            actions: [
              if (!forceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('LATER'),
                ),
              FilledButton(
                onPressed: () async {
                  if (downloadUrl.isNotEmpty) {
                    final uri = Uri.parse(downloadUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
                child: const Text('UPDATE NOW'),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      // Silently ignore version check failures
    }
  }
}
