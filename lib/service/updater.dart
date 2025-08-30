// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

class ReleaseInfo {
  final Version version;
  final String notes;
  ReleaseInfo({required this.version, required this.notes});
}

class UpdateService with ChangeNotifier {
  static const _lastCheckKey = 'last_update_check';
  ReleaseInfo? _latestRelease;
  bool _isUpdateAvailable = false;

  bool get isUpdateAvailable => _isUpdateAvailable;
  ReleaseInfo? get latestRelease => _latestRelease;

  Future<void> silentCheckForUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckString = prefs.getString(_lastCheckKey);

    if (lastCheckString != null) {
      final lastCheck = DateTime.parse(lastCheckString);
      if (DateTime.now().difference(lastCheck).inHours < 24) {
        if (kDebugMode) {
          print("Verificação de atualização pulada (menos de 24h).");
        }
        return;
      }
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/hendrilmendes/Wally/releases/latest',
        ),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final releaseJson = json.decode(response.body);
        final packageInfo = await PackageInfo.fromPlatform();

        final latestVersion = Version.parse(
          releaseJson['tag_name'].replaceAll('v', ''),
        );
        final currentVersion = Version.parse(packageInfo.version);

        if (latestVersion > currentVersion) {
          _latestRelease = ReleaseInfo(
            version: latestVersion,
            notes: releaseJson['body'] ?? 'Sem notas de versão.',
          );
          _isUpdateAvailable = true;
          if (kDebugMode) print("Nova versão encontrada: $latestVersion");
          notifyListeners();
        } else {
          if (kDebugMode) print("O App já está atualizado.");
        }
      }
      await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
    } catch (e) {
      if (kDebugMode) print("Erro ao verificar atualizações: $e");
    }
  }

  void showUpdateDialog(BuildContext context) {
    if (!_isUpdateAvailable || _latestRelease == null) return;

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final releaseInfo = _latestRelease!;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        Icons.system_update_alt_rounded,
                        size: 30,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.newUpdate,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Versão ${releaseInfo.version} disponível!",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      releaseInfo.notes,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.after),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final Uri uri = Platform.isAndroid
                                ? Uri.parse(
                                    'https://play.google.com/store/apps/details?id=com.github.hendrilmendes.projectx',
                                  )
                                : Uri.parse(
                                    'https://github.com/hendrilmendes/Wally/releases/latest',
                                  );
                            launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                            Navigator.pop(context);
                          },
                          child: Text(l10n.download),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
