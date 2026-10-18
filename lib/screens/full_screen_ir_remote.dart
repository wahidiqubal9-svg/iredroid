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
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(child: _buildGrid(context)),
                _buildHint(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 0),
      child: Row(
        children: [
          Icon(
            _iconFor(widget.device.category),
            size: 18,
            color: Colors.white70,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.device.category} · '
                  '${widget.device.buttons.length} buttons',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
          if (widget.onAddToHome != null)
            IconButton(
              tooltip: _added ? 'Added to My Remotes' : 'Add to My Remotes',
              icon: Icon(
                _added ? Icons.check_circle : Icons.add_circle_outline,
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
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        childAspectRatio: 1.35,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: widget.device.buttons.length,
      itemBuilder: (context, index) {
        final button = widget.device.buttons[index];
        return ElevatedButton(
          onPressed: () async {
            Haptics.tap();
            try {
              await IRTransmitter.transmitButton(button);
            } catch (_) {
              // ignore transmit errors
            }
          },
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildHint() {
    return const Padding(
      padding: EdgeInsets.only(top: 6, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pinch, size: 14, color: Colors.white38),
          SizedBox(width: 6),
          Text(
            'Pinch with two fingers to close',
            style: TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Future<void> _addToHome() async {
    final add = widget.onAddToHome;
    if (add == null) return;
    final ok = await add();
    if (!mounted) return;
    if (ok) {
      setState(() => _added = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to My Remotes')));
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
