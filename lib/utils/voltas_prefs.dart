import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Last AC state shown by the Voltas remote.
class VoltasState {
  const VoltasState({
    required this.mode,
    required this.fan,
    required this.temp,
    required this.acOn,
  });

  final int mode;
  final int fan;
  final int temp;
  final bool acOn;

  factory VoltasState.fromJson(Map<String, dynamic> json) {
    return VoltasState(
      mode: (json['mode'] as num?)?.toInt() ?? 0,
      fan: (json['fan'] as num?)?.toInt() ?? 0,
      temp: (json['temp'] as num?)?.toInt() ?? 22,
      acOn: json['ac_on'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'fan': fan,
    'temp': temp,
    'ac_on': acOn,
  };
}

/// Remembers which of the 11 Voltas remote varieties the user picked, so the
/// remote only ever shows the one that works for their AC unit. It also stores
/// the last mode/fan/temperature so reopening the remote does not reset them.
class VoltasPrefs {
  static const String _fileName = 'voltas_variety.txt';
  static const String _stateFileName = 'voltas_state.json';
  static const int varietyCount = 11;

  static Future<int> getVariety() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (await file.exists()) {
        final value = int.tryParse((await file.readAsString()).trim());
        if (value != null && value >= 1 && value <= varietyCount) {
          return value;
        }
      }
    } catch (_) {
      // fall through to default
    }
    return 1;
  }

  static Future<void> setVariety(int variety) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      await File('${dir.path}/$_fileName').writeAsString('$variety');
    } catch (_) {
      // ignore persistence errors
    }
  }

  static Future<VoltasState?> getState() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_stateFileName');
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      return VoltasState.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setState(VoltasState state) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      await File(
        '${dir.path}/$_stateFileName',
      ).writeAsString(jsonEncode(state.toJson()));
    } catch (_) {
      // ignore persistence errors
    }
  }
}
