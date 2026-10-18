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
  static const MethodChannel _windowChannel = MethodChannel(
    'org.nslabs/window',
  );

  @override
  void initState() {
    super.initState();
    _enterFullscreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _enterFullscreen();
    });
  }

  @override
  void dispose() {
    _leaveFullscreen();
    super.dispose();
  }

  Future<void> _enterFullscreen() async {
    try {
      await _windowChannel.invokeMethod('setFullscreen', {'enabled': true});
    } catch (_) {
      // Fall back to Flutter's system UI control.
    }
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
    } catch (_) {
      // System UI control is unavailable on some platforms.
    }
  }

  Future<void> _leaveFullscreen() async {
    try {
      await _windowChannel.invokeMethod('setFullscreen', {'enabled': false});
    } catch (_) {
      // Ignore if the platform channel is unavailable.
    }
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
