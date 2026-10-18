import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class AppSettings {
  static const String _settingsFileName = 'app_settings.json';

  // Default values
  static const bool defaultTransmitterAvailable = true;
  static const String _builtinRemotesKey = 'builtin_remotes';
  static const String _lastUpdateCheckKey = 'last_update_check';

  // Get settings file
  static Future<File> _getSettingsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_settingsFileName');
  }

  // Load settings from file
  static Future<Map<String, dynamic>> _loadSettings() async {
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        return json.decode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      // Return default values if file doesn't exist or is corrupted
    }
    return {'transmitter_available': defaultTransmitterAvailable};
  }

  // Save settings to file
  static Future<void> _saveSettings(Map<String, dynamic> settings) async {
    try {
      final file = await _getSettingsFile();
      await file.writeAsString(json.encode(settings));
    } catch (e) {
      // Ignore save errors
    }
  }

  // Get transmitter availability
  static Future<bool> getTransmitterAvailable() async {
    final settings = await _loadSettings();
    return settings['transmitter_available'] as bool? ??
        defaultTransmitterAvailable;
  }

  // Set transmitter availability
  static Future<void> setTransmitterAvailable(bool available) async {
    final settings = await _loadSettings();
    settings['transmitter_available'] = available;
    await _saveSettings(settings);
  }

  // Built-in remotes the user has added to their home screen.
  static Future<List<String>> getBuiltinRemotes() async {
    final settings = await _loadSettings();
    final value = settings[_builtinRemotesKey];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return <String>[];
  }

  static Future<bool> addBuiltinRemote(String id) async {
    final settings = await _loadSettings();
    final value = settings[_builtinRemotesKey];
    final ids = value is List ? value.whereType<String>().toList() : <String>[];
    if (ids.contains(id)) return false;
    ids.add(id);
    settings[_builtinRemotesKey] = ids;
    await _saveSettings(settings);
    return true;
  }

  static Future<void> removeBuiltinRemote(String id) async {
    final settings = await _loadSettings();
    final value = settings[_builtinRemotesKey];
    if (value is! List) return;
    final ids = value.whereType<String>().toList()..remove(id);
    settings[_builtinRemotesKey] = ids;
    await _saveSettings(settings);
  }

  static Future<int> getLastUpdateCheck() async {
    final settings = await _loadSettings();
    final value = settings[_lastUpdateCheckKey];
    return value is int ? value : 0;
  }

  static Future<void> setLastUpdateCheck(int millisecondsSinceEpoch) async {
    final settings = await _loadSettings();
    settings[_lastUpdateCheckKey] = millisecondsSinceEpoch;
    await _saveSettings(settings);
  }
}
