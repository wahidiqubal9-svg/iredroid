import 'package:flutter/material.dart';

/// A small remote-shaped preview shown next to a saved remote.
class MiniRemotePreview extends StatelessWidget {
  /// Voltas-style digital LCD look.
  final bool digital;

  /// Optional category icon drawn on the little screen.
  final IconData? icon;

  const MiniRemotePreview({
    super.key,
    this.digital = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 58,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A2A), Color(0xFF141414)],
        ),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          // Little screen
          Container(
            height: 18,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: digital ? const Color(0xFF03130C) : const Color(0xFF101010),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.black),
            ),
            child: digital
                ? const Text('24°',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Color(0xFF6EE7A0)))
                : Icon(icon ?? Icons.settings_remote,
                    size: 12, color: Colors.white54),
          ),
          const SizedBox(height: 4),
          // Button dots
          Expanded(
            child: Wrap(
              spacing: 3,
              runSpacing: 3,
              children: List.generate(
                6,
                (i) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == 0
                        ? const Color(0xFFFF8C00)
                        : Colors.white24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
