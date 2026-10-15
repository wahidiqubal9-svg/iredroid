import 'package:flutter/material.dart';

import '../models/ir_device.dart';
import '../utils/ir_transmitter.dart';
import '../widgets/pinch_to_exit.dart';

/// A saved remote shown full-screen. Pinch in with two fingers to close.
class FullScreenIRRemote extends StatelessWidget {
  final IRDevice device;

  const FullScreenIRRemote({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: PinchToExit(
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
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 0),
      child: Row(
        children: [
          Icon(_iconFor(device.category), size: 18, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${device.category} · ${device.buttons.length} buttons',
                    style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            ),
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
      itemCount: device.buttons.length,
      itemBuilder: (context, index) {
        final button = device.buttons[index];
        return ElevatedButton(
          onPressed: () async {
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
          Text('Pinch with two fingers to close',
              style: TextStyle(fontSize: 11, color: Colors.white38)),
        ],
      ),
    );
  }

  IconData _iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'tv':
        return Icons.tv;
      case 'ac':
        return Icons.ac_unit;
      case 'audio':
        return Icons.speaker;
      case 'fan':
        return Icons.toys;
      case 'light':
        return Icons.lightbulb;
      default:
        return Icons.settings_remote;
    }
  }
}
