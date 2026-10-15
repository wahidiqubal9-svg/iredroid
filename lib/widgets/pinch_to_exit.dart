import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a remote full-screen (hiding the system bars) and lets the user leave
/// it with a two-finger pinch-in gesture (zoom out), like closing a photo.
///
/// Uses a [Listener] so it never steals taps from the buttons underneath —
/// it only observes pointer positions.
class PinchToExit extends StatefulWidget {
  final Widget child;

  /// Ratio of the two-finger distance that counts as "zoomed out" (0..1).
  final double threshold;

  /// Overrides the default [Navigator.maybePop].
  final VoidCallback? onExit;

  /// Hide the status/navigation bars while this remote is visible.
  final bool immersive;

  const PinchToExit({
    super.key,
    required this.child,
    this.threshold = 0.7,
    this.onExit,
    this.immersive = true,
  });

  @override
  State<PinchToExit> createState() => _PinchToExitState();
}

class _PinchToExitState extends State<PinchToExit> {
  final Map<int, Offset> _pointers = {};
  double? _startDistance;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    if (widget.immersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    if (widget.immersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  double? _distance() {
    if (_pointers.length < 2) return null;
    final pts = _pointers.values.toList(growable: false);
    return (pts[0] - pts[1]).distance;
  }

  void _onDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.position;
    if (_pointers.length >= 2) _startDistance ??= _distance();
  }

  void _onMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) {
      _pointers[event.pointer] = event.position;
    }
    _pointers[event.pointer] = event.position;

    if (_pointers.length >= 2) {
      if (_startDistance == null) {
        _startDistance = _distance();
        return;
      }
      final d = _distance();
      if (d != null &&
          _startDistance! > 0 &&
          d < _startDistance! * widget.threshold) {
        _exit();
      }
    }
  }

  void _onUp(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.length < 2) _startDistance = null;
  }

  void _exit() {
    if (_exiting) return;
    _exiting = true;
    if (widget.onExit != null) {
      widget.onExit!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onUp,
      child: widget.child,
    );
  }
}
