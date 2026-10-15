import 'package:flutter/material.dart';

import '../models/ir_device.dart';
import '../utils/haptics.dart';
import '../utils/ir_transmitter.dart';
import '../widgets/pinch_to_exit.dart';

/// A single Atomberg fan button: label + NECext command byte.
class _FanButton {
  final String label;
  final String command;
  const _FanButton(this.label, this.command);
}

/// Full-screen Atomberg ceiling-fan remote, styled after the original white
/// IR remote (Power, speeds 1-5, Boost, Timer, LED, Sleep).
///
/// Codes come from the bundled Flipper IRDB (Fans/Atomberg): NECext,
/// address 00 F3. Pinch in with two fingers to close.
class AtombergRemoteScreen extends StatelessWidget {
  const AtombergRemoteScreen({super.key});

  static const String _address = '00 F3 00 00';

  static const List<_FanButton> _speed = [
    _FanButton('1', '8B 74'),
    _FanButton('2', '90 6F'),
    _FanButton('3', '8A 75'),
    _FanButton('4', '93 6C'),
    _FanButton('5', '88 77'),
  ];

  static const List<_FanButton> _modes = [
    _FanButton('BOOST', '8F 70'),
    _FanButton('TIMER', '96 69'),
    _FanButton('LED', '97 68'),
    _FanButton('SLEEP', '8E 71'),
  ];

  static const _FanButton _power = _FanButton('POWER', '91 6E');

  Future<void> _send(_FanButton button) async {
    Haptics.tap();
    try {
      await IRTransmitter.transmitButton(IRButton(
        name: button.label,
        type: 'parsed',
        protocol: 'NECext',
        address: _address,
        command: button.command,
      ));
    } catch (_) {
      // ignore transmit errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: PinchToExit(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: _buildRemote(),
                    ),
                  ),
                ),
              ),
              _buildHint(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
      child: Row(
        children: [
          const Icon(Icons.toys, size: 18, color: Colors.white70),
          const SizedBox(width: 10),
          const Text('Atomberg Fan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _buildRemote() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          const Text('Atomberg',
              style: TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3)),
          const SizedBox(height: 18),
          _buildPower(),
          const SizedBox(height: 24),
          _label('SPEED'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _speed.map(_speedButton).toList(),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: _modes.map(_modeButton).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPower() {
    return GestureDetector(
      onTap: () => _send(_power),
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE53935),
          boxShadow: [
            BoxShadow(
                color: Color(0x55E53935), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: const Icon(Icons.power_settings_new, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _speedButton(_FanButton button) {
    return GestureDetector(
      onTap: () => _send(button),
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD0D0D0), width: 1.5),
        ),
        child: Text(button.label,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333))),
      ),
    );
  }

  Widget _modeButton(_FanButton button) {
    return GestureDetector(
      onTap: () => _send(button),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFEAEAEA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD6D6D6)),
        ),
        child: Text(button.label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Color(0xFF444444))),
      ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text,
          style: const TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              color: Color(0xFF9A9A9A),
              fontWeight: FontWeight.bold)),
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
}
