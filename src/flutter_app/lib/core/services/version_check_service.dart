import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../di/injection.dart';
import '../network/api_client.dart';

class VersionCheckService {
  static bool _checkInProgress = false;

  static Future<void> checkForUpdate(BuildContext context) async {
    if (_checkInProgress || !Platform.isAndroid) return;

    _checkInProgress = true;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await getIt<ApiClient>().dio.get(
        '${AppConstants.serverUrl}/app-version/check',
        queryParameters: {'currentVersion': packageInfo.version},
      );

      final data = response.data;
      if (data is! Map || data['updateAvailable'] != true) return;

      final forceUpdate = data['forceUpdate'] == true;
      final latestVersion = data['latestVersion']?.toString() ?? '';
      final downloadUrl = data['downloadUrl']?.toString() ?? '';
      final releaseNotes = data['releaseNotes']?.toString() ?? '';

      if (!context.mounted || downloadUrl.isEmpty) return;

      await _showUpdateDialog(
        context: context,
        forceUpdate: forceUpdate,
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
      );
    } catch (_) {
      // Ignore version check failures so the app still opens offline.
    } finally {
      _checkInProgress = false;
    }
  }

  static Future<void> _showUpdateDialog({
    required BuildContext context,
    required bool forceUpdate,
    required String latestVersion,
    required String downloadUrl,
    required String releaseNotes,
  }) async {
    await showDialog<void>(
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
                Text(
                  releaseNotes,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
              if (forceUpdate) ...[
                const SizedBox(height: 12),
                const Text(
                  'This update is required to continue using the app.',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error),
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
                Navigator.pop(ctx);
                if (!context.mounted) return;
                await _downloadAndInstall(context, downloadUrl);
              },
              child: const Text('UPDATE NOW'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _downloadAndInstall(
    BuildContext context,
    String downloadUrl,
  ) async {
    if (!Platform.isAndroid) {
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final installPermission = await Permission.requestInstallPackages.request();
    if (!installPermission.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Allow app installs to update GoldDesk.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final progressNotifier = ValueNotifier<double>(0);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Downloading Update'),
          content: ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (context, progress, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress > 0 ? progress : null),
                  const SizedBox(height: 12),
                  Text(
                    progress > 0
                        ? '${(progress * 100).toStringAsFixed(0)}%'
                        : 'Preparing download...',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/golddesk-update.apk';

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );

      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          progressNotifier.value = received / total;
        },
      );

      progressNotifier.dispose();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      progressNotifier.dispose();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update download failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
