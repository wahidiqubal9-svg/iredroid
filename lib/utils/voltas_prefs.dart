import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Remembers which of the 11 Voltas remote varieties the user picked, so the
/// remote only ever shows the one that works for their AC unit.
class VoltasPrefs {
  static const String _fileName = 'voltas_variety.txt';
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
}
