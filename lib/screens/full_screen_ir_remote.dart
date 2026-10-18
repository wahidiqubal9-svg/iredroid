import 'package:flutter/material.dart';

import '../models/ir_device.dart';
import '../utils/haptics.dart';
import '../utils/ir_transmitter.dart';
import '../widgets/immersive_mode.dart';
import '../widgets/pinch_to_exit.dart';

/// A saved remote shown full-screen. Pinch in with two fingers to close.
class FullScreenIRRemote extends StatefulWidget {
  final IRDevice device;
  final Future<bool> Function()? onAddToHome;

  const FullScreenIRRemote({super.key, required this.device, this.onAddToHome});

  @override
  State<FullScreenIRRemote> createState() => _FullScreenIRRemoteState();
}

class _FullScreenIRRemoteState extends State<FullScreenIRRemote> {
  bool _added = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: ImmersiveMode(
        child: PinchToExit(
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 58, 14, 14),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150,
                          childAspectRatio: 1.45,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: widget.device.buttons.length,
                    itemBuilder: (context, index) {
                      final button = widget.device.buttons[index];
                      return ElevatedButton(
                        onPressed: () => _send(button),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF232323),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.white12),
                          ),
                        ),
                        child: Text(
                          button.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 14,
                  right: 100,
                  child: _buildTitle(),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Row(
                    children: [
                      if (widget.onAddToHome != null)
                        IconButton(
                          tooltip: _added
                              ? 'Added to My Remotes'
                              : 'Add to My Remotes',
                          icon: Icon(
                            _added
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                          ),
                          onPressed: _added ? null : _addToHome,
                        ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Icon(
          _iconFor(widget.device.category),
          size: 16,
          color: Colors.white70,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            widget.device.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _send(IRButton button) async {
    Haptics.tap();
    try {
      await IRTransmitter.transmitButton(button);
    } catch (_) {
      // ignore transmit errors
    }
  }

  Future<void> _addToHome() async {
    final add = widget.onAddToHome;
    if (add == null) return;
    final ok = await add();
    if (!mounted) return;
    if (ok) {
      setState(() => _added = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to My Remotes')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add this remote')),
      );
    }
  }

  IconData _iconFor(String category) {
    final value = category.toLowerCase();
    if (value.contains('tv')) return Icons.tv;
    if (value.contains('ac') || value.contains('air')) return Icons.ac_unit;
    if (value.contains('audio') || value.contains('speaker')) {
      return Icons.speaker;
    }
    if (value.contains('fan')) return Icons.toys;
    if (value.contains('light')) return Icons.lightbulb;
    if (value.contains('projector')) return Icons.videocam;
    return Icons.settings_remote;
  }
}
