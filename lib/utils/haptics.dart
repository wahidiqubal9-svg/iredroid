import 'package:flutter/services.dart';

/// Small vibration helper used by every remote button.
class Haptics {
  /// Short tick for a normal button press.
  static Future<void> tap() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Haptics unsupported on this device.
    }
  }

  /// Lighter tick for selection chips.
  static Future<void> select() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Haptics unsupported on this device.
    }
  }
}
