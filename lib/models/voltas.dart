import 'dart:convert';
import 'package:flutter/services.dart';

/// A single raw IR signal: a carrier frequency (Hz) and a list of
/// mark/space durations in microseconds (starting with a mark).
class VoltasSignal {
  final int frequency;
  final List<int> data;

  const VoltasSignal(this.frequency, this.data);

  factory VoltasSignal.fromJson(Map<String, dynamic> json) {
    return VoltasSignal(
      json['frequency'] as int,
      (json['data'] as List).map((e) => e as int).toList(growable: false),
    );
  }
}

/// One Voltas remote "variety". The Play Store app ships 11 of them
/// (Remote 1..Remote 11); different Voltas units answer to different ones.
class VoltasRemote {
  final int number;

  /// Internal id from the original app (k, m, n, ...). Kept for provenance.
  final String id;

  final int tempMin;
  final int tempMax;

  /// Modes that do not take a temperature value (key uses temp = -1).
  final List<int> noTempModes;

  /// Modes that do not take a fan speed value (key uses fan = -1).
  final List<int> noFanModes;

  final VoltasSignal powerOn;
  final VoltasSignal powerOff;

  /// Combination ("mode,fan,temp") -> signal.
  final Map<String, VoltasSignal> codes;

  VoltasRemote({
    required this.number,
    required this.id,
    required this.tempMin,
    required this.tempMax,
    required this.noTempModes,
    required this.noFanModes,
    required this.powerOn,
    required this.powerOff,
    required this.codes,
  });

  factory VoltasRemote.fromJson(Map<String, dynamic> json) {
    final rawCodes = json['codes'] as Map<String, dynamic>;
    return VoltasRemote(
      number: json['number'] as int,
      id: json['id'] as String,
      tempMin: json['tempMin'] as int,
      tempMax: json['tempMax'] as int,
      noTempModes: (json['noTempModes'] as List).map((e) => e as int).toList(),
      noFanModes: (json['noFanModes'] as List).map((e) => e as int).toList(),
      powerOn: VoltasSignal.fromJson(json['powerOn'] as Map<String, dynamic>),
      powerOff: VoltasSignal.fromJson(json['powerOff'] as Map<String, dynamic>),
      codes: rawCodes.map(
        (k, v) => MapEntry(k, VoltasSignal.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }

  bool modeHasTemp(int mode) => !noTempModes.contains(mode);
  bool modeHasFan(int mode) => !noFanModes.contains(mode);

  /// Resolve the signal for a UI state, mirroring the original app:
  /// temp/fan are forced to -1 for modes that don't use them.
  VoltasSignal? codeFor(int mode, int fan, int temp) {
    final t = modeHasTemp(mode) ? temp : -1;
    final f = modeHasFan(mode) ? fan : -1;
    return codes['$mode,$f,$t'];
  }
}

/// The whole bundled Voltas dataset.
class VoltasDataset {
  final List<String> modeLabels;
  final List<String> fanLabels;
  final List<VoltasRemote> remotes;

  VoltasDataset({
    required this.modeLabels,
    required this.fanLabels,
    required this.remotes,
  });

  static const String assetPath = 'assets/voltas_codes.json';
  static VoltasDataset? _cache;

  static Future<VoltasDataset> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final meta = (json['meta'] as Map<String, dynamic>?) ?? const {};
    final dataset = VoltasDataset(
      modeLabels: ((meta['modeLabels'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      fanLabels: ((meta['fanLabels'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      remotes: (json['remotes'] as List)
          .map((e) => VoltasRemote.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _cache = dataset;
    return dataset;
  }
}
