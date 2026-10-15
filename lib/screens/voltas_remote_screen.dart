import 'package:flutter/material.dart';

import '../models/voltas.dart';
import '../utils/ir_transmitter.dart';

/// Stateful Voltas air-conditioner remote.
///
/// The Voltas protocol transmits the *entire* AC state in every frame
/// (mode + fan + temperature), so every control change re-sends the state.
/// The raw IR timings were reverse engineered from the Play Store app
/// "Remote For Voltas AC" (com.matanyamin.voltasacremotecontrol).
class VoltasRemoteScreen extends StatefulWidget {
  /// Optional 1-based "Remote N" variety to preselect (1..11).
  final int? initialRemote;

  const VoltasRemoteScreen({super.key, this.initialRemote});

  @override
  State<VoltasRemoteScreen> createState() => _VoltasRemoteScreenState();
}

class _VoltasRemoteScreenState extends State<VoltasRemoteScreen> {
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
      if (!mounted) return;
      final wanted = widget.initialRemote;
      final remote = (wanted != null &&
              dataset.remotes.any((r) => r.number == wanted))
          ? dataset.remotes.firstWhere((r) => r.number == wanted)
          : dataset.remotes.first;
      setState(() {
        _dataset = dataset;
        _remote = remote;
        _temp = 22.clamp(remote.tempMin, remote.tempMax);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  VoltasRemote get _r => _remote!;

  bool get _modeHasTemp => _r.modeHasTemp(_mode);
  bool get _modeHasFan => _r.modeHasFan(_mode);

  void _selectRemote(int number) {
    final remote = _dataset!.remotes.firstWhere((r) => r.number == number);
    setState(() {
      _remote = remote;
      _temp = _temp.clamp(remote.tempMin, remote.tempMax);
    });
  }

  Future<void> _sendSignal(VoltasSignal? signal) async {
    if (signal == null) {
      _toast('No code for this combination on Remote ${_r.number}');
      return;
    }
    try {
      await IRTransmitter.transmitRaw(signal.frequency, signal.data);
    } catch (e) {
      _toast('Transmit failed: $e');
    }
  }

  /// Re-send the full AC state (only when the unit is powered on).
  Future<void> _sendState() async {
    if (!_acOn) return;
    await _sendSignal(_r.codeFor(_mode, _fan, _temp));
  }

  Future<void> _togglePower() async {
    if (_acOn) {
      setState(() => _acOn = false);
      await _sendSignal(_r.powerOff);
    } else {
      setState(() => _acOn = true);
      await _sendSignal(_r.powerOn);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _sendState();
    }
  }

  void _setMode(int mode) {
    setState(() => _mode = mode);
    _sendState();
  }

  void _setFan(int fan) {
    setState(() => _fan = fan);
    _sendState();
  }

  void _setTemp(int temp) {
    setState(() => _temp = temp.clamp(_r.tempMin, _r.tempMax));
    _sendState();
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
      appBar: AppBar(
        title: const Text('Voltas AC'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Failed to load Voltas data:\n$_error'),
        ),
      );
    }
    if (_dataset == null || _remote == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final modes = _dataset!.modeLabels;
    final fans = _dataset!.fanLabels;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRemotePicker(),
          const SizedBox(height: 16),
          _buildDisplay(),
          const SizedBox(height: 16),
          _buildPowerButton(),
          const SizedBox(height: 20),
          _buildModeSelector(modes),
          const SizedBox(height: 20),
          _buildFanSelector(fans),
          const SizedBox(height: 20),
          _buildTempControl(),
          const SizedBox(height: 24),
          const Text(
            'Voltas AC units encode the whole state (mode + fan + temp) in '
            'every frame, so each change re-sends the full state. If nothing '
            'responds, try another remote variety above.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRemotePicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.settings_remote, size: 20),
            const SizedBox(width: 12),
            const Expanded(child: Text('Remote variety')),
            DropdownButton<int>(
              value: _r.number,
              underline: const SizedBox.shrink(),
              items: _dataset!.remotes
                  .map((r) => DropdownMenuItem(
                        value: r.number,
                        child: Text('Remote ${r.number}'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) _selectRemote(v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay() {
    return Card(
      color: _acOn ? Theme.of(context).colorScheme.surface : Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_modeIcon(_mode), size: 28),
                const SizedBox(width: 10),
                Text(
                  _dataset!.modeLabels[_mode],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _modeHasTemp ? '$_temp°C' : '--',
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _acOn ? 'ON  •  Fan: ${_modeHasFan ? _dataset!.fanLabels[_fan] : '-'}'
                    : 'OFF (press power)',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerButton() {
    return ElevatedButton.icon(
      onPressed: _togglePower,
      style: ElevatedButton.styleFrom(
        backgroundColor: _acOn ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
      ),
      icon: const Icon(Icons.power_settings_new),
      label: Text(_acOn ? 'Turn OFF' : 'Turn ON',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildModeSelector(List<String> modes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(modes.length, (i) {
            final selected = i == _mode;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _choice(
                  icon: _modeIcon(i),
                  label: modes[i],
                  selected: selected,
                  onTap: () => _setMode(i),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFanSelector(List<String> fans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fan speed', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(fans.length, (i) {
            final enabled = _modeHasFan;
            final selected = enabled && i == _fan;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _choice(
                  icon: i == fans.length - 1 ? Icons.autorenew : Icons.air,
                  label: fans[i],
                  selected: selected,
                  enabled: enabled,
                  onTap: () => _setFan(i),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTempControl() {
    final enabled = _modeHasTemp;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Temperature', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _roundButton(
                icon: Icons.remove,
                onTap: enabled && _temp > _r.tempMin
                    ? () => _setTemp(_temp - 1)
                    : null,
              ),
              Container(
                width: 90,
                alignment: Alignment.center,
                child: Text('$_temp°C',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              _roundButton(
                icon: Icons.add,
                onTap: enabled && _temp < _r.tempMax
                    ? () => _setTemp(_temp + 1)
                    : null,
              ),
            ],
          ),
          Center(
            child: Text('Range ${_r.tempMin}–${_r.tempMax}°C',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _choice({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : Colors.grey.shade700),
          color: selected ? color.withOpacity(0.15) : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: enabled ? null : Colors.grey),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _roundButton({required IconData icon, VoidCallback? onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        minimumSize: const Size(52, 52),
      ),
    );
  }
}
