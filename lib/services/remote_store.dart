import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/ir_device.dart';
import '../utils/app_settings.dart';
import '../utils/ir_file_parser.dart';

/// A remote shown on the home screen.
///
/// File-backed remotes live in Documents/Custom and can be edited or deleted.
/// Built-in remotes are rendered from code and tracked in app_settings.json.
class SavedRemote {
  const SavedRemote({
    required this.device,
    this.filePath,
    this.builtinId,
    this.modifiedAt,
  });

  final IRDevice device;
  final String? filePath;
  final String? builtinId;
  final DateTime? modifiedAt;

  bool get isBuiltin => builtinId != null;
  bool get isFileBacked => filePath != null;
}

/// Single source of truth for remotes saved on this device.
class RemoteStore {
  static const String builtinVoltas = 'voltas';
  static const String builtinAtomberg = 'atomberg';

  static const List<String> builtinOrder = [builtinVoltas, builtinAtomberg];

  static Future<Directory> _customDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final custom = Directory(p.join(directory.path, 'Custom'));
    if (!await custom.exists()) {
      await custom.create(recursive: true);
    }
    return custom;
  }

  static Future<List<SavedRemote>> loadAll() async {
    final remotes = <SavedRemote>[];

    final addedBuiltins = await AppSettings.getBuiltinRemotes();
    for (final id in builtinOrder) {
      if (!addedBuiltins.contains(id)) continue;
      final device = builtinDevice(id);
      if (device != null) {
        remotes.add(SavedRemote(device: device, builtinId: id));
      }
    }

    try {
      final custom = await _customDirectory();
      final files = custom
          .listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.ir'))
          .toList();

      final loaded = <SavedRemote>[];
      for (final file in files) {
        try {
          final content = await file.readAsString();
          final device = IRFileParser.parseIRFileContent(
            content,
            p.basenameWithoutExtension(file.path),
          );
          if (device == null || device.buttons.isEmpty) continue;
          loaded.add(
            SavedRemote(
              device: device,
              filePath: file.path,
              modifiedAt: file.statSync().modified,
            ),
          );
        } catch (_) {
          // Skip unreadable files.
        }
      }

      loaded.sort((a, b) {
        final aTime = a.modifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.modifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      // Older app versions saved favorites under a different file name. Keep
      // one card per brand/name pair so those don't show up twice.
      final seen = <String>{};
      for (final remote in loaded) {
        final key = '${remote.device.brand}|${remote.device.name}'
            .toLowerCase();
        if (seen.add(key)) remotes.add(remote);
      }
    } catch (_) {
      // No saved remotes yet.
    }

    return remotes;
  }

  static IRDevice? builtinDevice(String id) {
    switch (id) {
      case builtinVoltas:
        return IRDevice(
          name: 'Voltas AC',
          brand: 'Voltas',
          category: 'AC',
          buttons: const [],
          description: 'Built-in smart air conditioner remote',
        );
      case builtinAtomberg:
        return IRDevice(
          name: 'Atomberg Fan',
          brand: 'Atomberg',
          category: 'Fan',
          buttons: const [],
          description: 'Built-in smart ceiling fan remote',
        );
      default:
        return null;
    }
  }

  static Future<bool> addBuiltin(String id) async {
    final added = await AppSettings.addBuiltinRemote(id);
    return added;
  }

  static Future<String> saveDevice(IRDevice device, {String? source}) async {
    final custom = await _customDirectory();
    final fileName = '${_safeName(device.brand)}_${_safeName(device.name)}.ir';
    final file = File(p.join(custom.path, fileName));
    await file.writeAsString(serialize(device, source: source));
    return file.path;
  }

  static Future<void> updateDevice(
    SavedRemote saved,
    IRDevice device, {
    String? source,
  }) async {
    final path = saved.filePath;
    if (path == null) return;
    await File(path).writeAsString(serialize(device, source: source));
  }

  static Future<void> delete(SavedRemote remote) async {
    if (remote.builtinId != null) {
      await AppSettings.removeBuiltinRemote(remote.builtinId!);
      return;
    }
    final path = remote.filePath;
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<void> saveFromFuzzer(IRDevice device) async {
    await saveDevice(device, source: 'Fuzzer discovery');
  }

  static String serialize(IRDevice device, {String? source}) {
    final buffer = StringBuffer()
      ..writeln('Filetype: IR signals file')
      ..writeln('Version: 1')
      ..writeln('#')
      ..writeln('# Device: ${device.name}')
      ..writeln('# Brand: ${device.brand}')
      ..writeln('# Category: ${device.category}');
    if (source != null && source.isNotEmpty) {
      buffer.writeln('# Source: $source');
    }
    buffer.writeln('#');

    for (final button in device.buttons) {
      buffer.writeln('name: ${button.name}');
      buffer.writeln('type: ${button.type}');
      if (button.protocol != null) {
        buffer.writeln('protocol: ${button.protocol}');
      }
      if (button.address != null) {
        buffer.writeln('address: ${button.address}');
      }
      if (button.command != null) {
        buffer.writeln('command: ${button.command}');
      }
      if (button.frequency != null) {
        buffer.writeln('frequency: ${button.frequency}');
      }
      if (button.dutyCycle != null) {
        buffer.writeln('duty_cycle: ${button.dutyCycle}');
      }
      if (button.data != null && button.data!.isNotEmpty) {
        buffer.writeln('data: ${button.data!.join(' ')}');
      }
      buffer.writeln('#');
    }

    return buffer.toString();
  }

  static String _safeName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[^\w\s.-]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    final safe = cleaned.replaceAll(RegExp(r'^[_ .]+|[_ .]+$'), '');
    if (safe.isEmpty) return 'remote';
    return safe.length > 80 ? safe.substring(0, 80) : safe;
  }
}
