import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Represents the remote version info fetched from GitHub.
class RemoteVersionInfo {
  final String version;
  final int buildNumber;
  final String releaseNotes;
  final String downloadUrl;

  RemoteVersionInfo({
    required this.version,
    required this.buildNumber,
    required this.releaseNotes,
    required this.downloadUrl,
  });

  factory RemoteVersionInfo.fromJson(Map<String, dynamic> json) {
    return RemoteVersionInfo(
      version: json['version'] as String? ?? '0.0.0',
      buildNumber: json['buildNumber'] as int? ?? 0,
      releaseNotes: json['releaseNotes'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? '',
    );
  }
}

/// Service that checks for updates on GitHub and opens a download link
/// in the browser if a new version is available.
class UpdateService {
  static const String _versionUrl =
      'https://raw.githubusercontent.com/brdsllg/app/main/version.json';

  static const String _lastCheckKey = 'update_last_check_date';
  static const String _lastBuildKey = 'update_last_available_build';
  static const String _lastDownloadUrlKey = 'update_last_download_url';

  /// Checks for an update at most once per day (by date).
  /// Returns the remote version info if an update is available, or null if
  /// the app is up to date or the check fails.
  static Future<RemoteVersionInfo?> checkForUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // --- daily cooldown --------------------------------------------------
      final lastCheck = prefs.getString(_lastCheckKey);
      final today = DateTime.now().toIso8601String().split('T').first;
      if (lastCheck == today) {
        // Already checked today — use cached result
        final cachedBuild = prefs.getInt(_lastBuildKey);
        if (cachedBuild == null) return null;
        final local = await PackageInfo.fromPlatform();
        final localBuild = int.tryParse(local.buildNumber) ?? 0;
        if (cachedBuild <= localBuild) return null;
        final cachedUrl = prefs.getString(_lastDownloadUrlKey) ?? '';
        return RemoteVersionInfo(
          version: '',
          buildNumber: cachedBuild,
          releaseNotes: '',
          downloadUrl: cachedUrl,
        );
      }

      // --- fetch remote version.json ---------------------------------------
      final response = await http.get(Uri.parse(_versionUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) return null;

      final remote = RemoteVersionInfo.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      // --- compare build numbers -------------------------------------------
      final local = await PackageInfo.fromPlatform();
      final localBuild = int.tryParse(local.buildNumber) ?? 0;

      final updateAvailable = remote.buildNumber > localBuild;

      // --- persist check date and result -----------------------------------
      await prefs.setString(_lastCheckKey, today);
      if (updateAvailable) {
        await prefs.setInt(_lastBuildKey, remote.buildNumber);
        await prefs.setString(_lastDownloadUrlKey, remote.downloadUrl);
        return remote;
      } else {
        await prefs.remove(_lastBuildKey);
        await prefs.remove(_lastDownloadUrlKey);
        return null;
      }
    } catch (_) {
      return null; // network / parse error — fail silently
    }
  }

  /// Runs the update check and, if an update is available, shows a dialog
  /// with a "Download" button that opens the download URL in the device browser.
  static Future<void> runUpdateFlow(BuildContext context) async {
    final remote = await checkForUpdate();
    if (remote == null) return; // up-to-date or error

    if (!context.mounted) return;

    final shouldDownload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Version ${remote.version} is now available.'),
                if (remote.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'What\'s new:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(remote.releaseNotes),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Download'),
            ),
          ],
        );
      },
    );

    if (shouldDownload != true) return;

    // Open the download URL in the browser
    final uri = Uri.tryParse(remote.downloadUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open download link.')),
        );
      }
    }
  }
}