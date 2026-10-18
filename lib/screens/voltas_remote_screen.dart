import 'dart:async';

import 'package:flutter/material.dart';

import '../models/voltas.dart';
import '../utils/haptics.dart';
import '../utils/ir_transmitter.dart';
import '../utils/voltas_prefs.dart';
import '../widgets/immersive_mode.dart';
import '../widgets/pinch_to_exit.dart';

/// Full-screen Voltas AC remote with a digital display.
///
/// The Voltas protocol sends the *entire* AC state (mode + fan + temperature)
/// in every frame, so each control change re-sends the full state. Raw IR
/// timings were reverse engineered from the Play Store app "Remote For Voltas
/// AC" (com.matanyamin.voltasacremotecontrol).
///
/// Pinch in with two fingers to close the remote.
class VoltasRemoteScreen extends StatefulWidget {
  /// Optional 1-based "Remote N" variety to use. When null, the previously
  /// saved working variety is used (see [VoltasPrefs]).
  final int? initialRemote;

  const VoltasRemoteScreen({super.key, this.initialRemote});

  @override
  State<VoltasRemoteScreen> createState() => _VoltasRemoteScreenState();
}

class _VoltasRemoteScreenState extends State<VoltasRemoteScreen> {
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _lcdBg = Color(0xFF03130C);
  static const Color _lcdInk = Color(0xFF6EE7A0);
  static const Color _accent = Color(0xFFFF8C00);

  VoltasDataset? _dataset;
  VoltasRemote? _remote;
  Object? _error;

  int _mode = 0;
  int _fan = 0;
  int _temp = 22;
  bool _acOn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dataset = await VoltasDataset.load();
      final wanted = widget.initialRemote ?? await VoltasPrefs.getVariety();
      if (!mounted) return;
      final remote = dataset.remotes.any((r) => r.number == wanted)
          ? dataset.remotes.firstWhere((r) => r.number == wanted)
          : dataset.remotes.first;
      final saved = await VoltasPrefs.getState();
      final mode = (saved?.mode ?? 0)
          .clamp(0, dataset.modeLabels.length - 1)
          .toInt();
      final fan = (saved?.fan ?? 0)
          .clamp(0, dataset.fanLabels.length - 1)
          .toInt();
      final temp = (saved?.temp ?? 22)
          .clamp(remote.tempMin, remote.tempMax)
          .toInt();
      setState(() {
        _dataset = dataset;
        _remote = remote;
        _mode = mode;
        _fan = fan;
        _temp = temp;
        _acOn = saved?.acOn ?? false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  VoltasRemote get _r => _remote!;
  bool get _modeHasTemp => _r.modeHasTemp(_mode);
  bool get _modeHasFan => _r.modeHasFan(_mode);
  String get _tempText => _modeHasTemp ? '$_temp' : '--';

  Future<void> _sendSignal(VoltasSignal? signal) async {
    if (signal == null) {
      _toast('No code on Remote ${_r.number} for this combination');
      return;
    }
    try {
      await IRTransmitter.transmitRaw(signal.frequency, signal.data);
    } catch (e) {
      _toast('Transmit failed: $e');
    }
  }

  Future<void> _sendState() async {
    if (!_acOn) return;
    await _sendSignal(_r.codeFor(_mode, _fan, _temp));
  }

  Future<void> _togglePower() async {
    Haptics.tap();
    if (_acOn) {
      setState(() => _acOn = false);
      unawaited(_persistState());
      await _sendSignal(_r.powerOff);
    } else {
      setState(() => _acOn = true);
      unawaited(_persistState());
      await _sendSignal(_r.powerOn);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _sendState();
    }
  }

  void _setMode(int mode) {
    Haptics.select();
    setState(() => _mode = mode);
    unawaited(_persistState());
    _sendState();
  }

  void _setFan(int fan) {
    Haptics.select();
    setState(() => _fan = fan);
    unawaited(_persistState());
    _sendState();
  }

  void _setTemp(int temp) {
    Haptics.tap();
    setState(() => _temp = temp.clamp(_r.tempMin, _r.tempMax));
    unawaited(_persistState());
    _sendState();
  }

  Future<void> _persistState() {
    return VoltasPrefs.setState(
      VoltasState(mode: _mode, fan: _fan, temp: _temp, acOn: _acOn),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  IconData _modeIcon(int mode) {
    switch (mode) {
      case 0:
        return Icons.ac_unit;
      case 1:
        return Icons.wb_sunny;
      case 2:
        return Icons.air;
      case 3:
        return Icons.water_drop;
      default:
        return Icons.mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: ImmersiveMode(
        child: PinchToExit(
          child: SafeArea(
            child: (_remote == null || _dataset == null)
                ? _buildLoading()
                : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to load Voltas data:\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildContent() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF232323), Color(0xFF111111)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const padding = 12.0;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(padding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - padding * 2,
                    ),
                    child: _buildRemoteBody(),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLcd(),
        const SizedBox(height: 10),
        _buildModeRow(),
        const SizedBox(height: 8),
        _buildFanRow(),
        const SizedBox(height: 10),
        _buildTempRow(),
        const SizedBox(height: 10),
        _buildPowerButton(),
      ],
    );
  }

  Widget _buildLcd() {
    final fans = _dataset!.fanLabels;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: _lcdBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_modeIcon(_mode), size: 16, color: _lcdInk),
                  const SizedBox(width: 6),
                  Text(
                    _dataset!.modeLabels[_mode].toUpperCase(),
                    style: const TextStyle(
                      color: _lcdInk,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _acOn ? _lcdInk : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _acOn ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: _acOn ? _lcdInk : Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _tempText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 72,
                  height: 1.0,
                  color: _lcdInk,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '°C',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  color: _lcdInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.air, size: 14, color: _lcdInk),
                  const SizedBox(width: 5),
                  Text(
                    _modeHasFan ? fans[_fan].toUpperCase() : '—',
                    style: const TextStyle(
                      color: _lcdInk,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Text(
                'VOLTAS',
                style: TextStyle(
                  color: _lcdInk.withValues(alpha: 0.5),
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeRow() {
    final modes = _dataset!.modeLabels;
    return _labeledRow(
      'MODE',
      Row(
        children: List.generate(modes.length, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _choice(
                icon: _modeIcon(i),
                label: modes[i],
                selected: i == _mode,
                onTap: () => _setMode(i),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFanRow() {
    final fans = _dataset!.fanLabels;
    return _labeledRow(
      'FAN',
      Row(
        children: List.generate(fans.length, (i) {
          final enabled = _modeHasFan;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _choice(
                icon: i == fans.length - 1 ? Icons.autorenew : Icons.air,
                label: fans[i],
                selected: enabled && i == _fan,
                enabled: enabled,
                onTap: () => _setFan(i),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTempRow() {
    final enabled = _modeHasTemp;
    return _labeledRow(
      'TEMPERATURE',
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _round(
            icon: Icons.remove,
            onTap: enabled && _temp > _r.tempMin
                ? () => _setTemp(_temp - 1)
                : null,
          ),
          Container(
            width: 96,
            alignment: Alignment.center,
            child: Text(
              '$_temp°C',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          _round(
            icon: Icons.add,
            onTap: enabled && _temp < _r.tempMax
                ? () => _setTemp(_temp + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPowerButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _togglePower,
        style: ElevatedButton.styleFrom(
          backgroundColor: _acOn ? Colors.red : Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.power_settings_new),
        label: Text(
          _acOn ? 'TURN OFF' : 'TURN ON',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _labeledRow(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white54,
              letterSpacing: 1.5,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _choice({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _accent : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
          color: selected ? _accent.withValues(alpha: 0.12) : Colors.black26,
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: enabled ? null : Colors.white24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: enabled ? Colors.white70 : Colors.white24,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _round({required IconData icon, VoidCallback? onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      iconSize: 26,
      style: IconButton.styleFrom(
        backgroundColor: _accent.withValues(alpha: 0.15),
        minimumSize: const Size(58, 58),
      ),
    );
  }
}
