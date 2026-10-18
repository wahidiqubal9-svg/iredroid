import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hides the status and navigation bars while a remote is open, then restores
/// them when the remote is closed.
class ImmersiveMode extends StatefulWidget {
  const ImmersiveMode({super.key, required this.child});

  final Widget child;

  @override
  State<ImmersiveMode> createState() => _ImmersiveModeState();
}

class _ImmersiveModeState extends State<ImmersiveMode> {
  @override
  void initState() {
    super.initState();
    _applyImmersive();
  }

  @override
  void dispose() {
    _restoreSystemUi();
    super.dispose();
  }

  Future<void> _applyImmersive() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (_) {
      // System UI control is unavailable on some platforms.
    }
  }

  Future<void> _restoreSystemUi() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    } catch (_) {
      // System UI control is unavailable on some platforms.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
