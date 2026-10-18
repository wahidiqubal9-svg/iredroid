import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/app_settings.dart';

/// Version information reported by the Android package manager.
class InstalledAppVersion {
  const InstalledAppVersion({
    required this.versionCode,
    required this.versionName,
  });

  final int versionCode;
  final String versionName;
}

/// Update metadata published on the `apk` branch.
class AppUpdate {
  const AppUpdate({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    this.notes = '',
    this.sha256 = '',
  });

  final int versionCode;
  final String versionName;
  final String apkUrl;
  final String notes;
  final String sha256;

  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    return AppUpdate(
      versionCode: _asInt(json['versionCode']),
      versionName: (json['versionName'] ?? '').toString(),
      apkUrl: (json['apkUrl'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      sha256: (json['sha256'] ?? '').toString(),
    );
  }

  bool isNewerThan(InstalledAppVersion installed) {
    final comparison = UpdateManager.compareVersionNames(
      versionName,
      installed.versionName,
    );
    if (comparison != 0) return comparison > 0;

    // Version names are bumped on every build. If they match, this is the same
    // release. Avoid comparing version codes because split APKs use ABI offsets
    // and the universal APK intentionally uses a higher base code.
    return false;
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }
}

class UpdateManager {
  static const MethodChannel _channel = MethodChannel('org.nslabs/updater');
  static const String _versionUrl =
      'https://raw.githubusercontent.com/wahidiqubal9-svg/iredroid/apk/version.json';
  static const int _autoCheckIntervalMs = 5 * 60 * 1000;

  static Future<InstalledAppVersion> installedVersion() async {
    final value = await _channel.invokeMapMethod<String, dynamic>('getVersion');
    final code = value?['versionCode'];
    final name = value?['versionName'];
    return InstalledAppVersion(
      versionCode: code is int ? code : int.tryParse('$code') ?? 0,
      versionName: name is String && name.isNotEmpty ? name : '0.0.0',
    );
  }

  /// Returns the newer release, or null when up to date / offline.
  static Future<AppUpdate?> check() async {
    try {
      final installed = await installedVersion();
      final client = HttpClient();
      try {
        final request = await client.getUrl(
          Uri.parse('$_versionUrl?t=${DateTime.now().millisecondsSinceEpoch}'),
        );
        request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
        request.headers.set(HttpHeaders.pragmaHeader, 'no-cache');
        final response = await request.close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return null;
        }
        final body = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) return null;

        final update = AppUpdate.fromJson(decoded);
        if (update.apkUrl.isEmpty || !update.isNewerThan(installed)) {
          return null;
        }
        return update;
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      return null;
    }
  }

  static Future<File> download(AppUpdate update) async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'updates'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    for (final entity in directory.listSync()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.apk')) {
        try {
          await entity.delete();
        } catch (_) {
          // Ignore files that are already gone / in use.
        }
      }
    }

    final file = File(
      p.join(directory.path, 'iredroid-${_safe(update.versionName)}.apk'),
    );
    final client = HttpClient();
    try {
      final uri = Uri.parse(update.apkUrl);
      final downloadUri = uri.replace(
        queryParameters: {...uri.queryParameters, 'v': '${update.versionCode}'},
      );
      final request = await client.getUrl(downloadUri);
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Download failed (${response.statusCode})');
      }

      final expectedLength = response.contentLength;
      await response.pipe(file.openWrite());

      final length = await file.length();
      if (length == 0) {
        throw const FileSystemException('Downloaded APK is empty');
      }
      if (expectedLength > 0 && length != expectedLength) {
        throw const FileSystemException('Download was incomplete');
      }
      return file;
    } finally {
      client.close(force: true);
    }
  }

  static Future<bool> canInstallPackages() async {
    try {
      return await _channel.invokeMethod<bool>('canInstallPackages') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> needsInstallPermission() async {
    return !(await canInstallPackages());
  }

  static Future<void> openInstallPermissionSettings() async {
    try {
      await _channel.invokeMethod('openInstallSettings');
    } catch (_) {
      // The user can still grant it from Android settings manually.
    }
  }

  static Future<bool> install(File file) async {
    try {
      return await _channel.invokeMethod<bool>('installApk', {
            'path': file.path,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> shouldAutoCheck() async {
    final last = await AppSettings.getLastUpdateCheck();
    return DateTime.now().millisecondsSinceEpoch - last >= _autoCheckIntervalMs;
  }

  static Future<void> markChecked() async {
    await AppSettings.setLastUpdateCheck(DateTime.now().millisecondsSinceEpoch);
  }

  static int compareVersionNames(String a, String b) {
    final left = _numericParts(a);
    final right = _numericParts(b);
    if (left.isEmpty || right.isEmpty) return 0;

    final length = left.length > right.length ? left.length : right.length;
    for (var i = 0; i < length; i++) {
      final l = i < left.length ? left[i] : 0;
      final r = i < right.length ? right[i] : 0;
      if (l != r) return l.compareTo(r);
    }
    return 0;
  }

  static List<int> _numericParts(String value) {
    return value
        .split(RegExp(r'[^0-9]+'))
        .where((part) => part.isNotEmpty)
        .map(int.tryParse)
        .whereType<int>()
        .toList();
  }

  static String _safe(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '_');
    return cleaned.isEmpty ? 'latest' : cleaned;
  }
}
