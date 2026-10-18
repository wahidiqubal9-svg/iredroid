import 'package:flutter/material.dart';

import '../services/update_manager.dart';
import '../utils/ir_transmitter.dart';
import '../widgets/update_prompt.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool enableVibration = true;
  bool? irAvailable;
  List<String>? supportedProtocols;
  InstalledAppVersion? _version;
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _checkIRCapabilities();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final version = await UpdateManager.installedVersion();
      if (mounted) setState(() => _version = version);
    } catch (_) {
      // Keep the generic version label if the platform channel is unavailable.
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _checkingUpdate = true);
    final update = await UpdateManager.check();
    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    if (update == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're on the latest version")),
      );
      return;
    }
    await showUpdatePrompt(context, update);
  }

  Future<void> _checkIRCapabilities() async {
    try {
      final available = await IRTransmitter.isIRAvailable();
      final protocols = await IRTransmitter.getSupportedProtocols();

      if (mounted) {
        setState(() {
          irAvailable = available;
          supportedProtocols = protocols;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          irAvailable = false;
          supportedProtocols = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // IR Hardware Status
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'IR Hardware Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                leading: Icon(
                  irAvailable == null
                      ? Icons.sync
                      : irAvailable!
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: irAvailable == null
                      ? Colors.orange
                      : irAvailable!
                      ? Colors.green
                      : Colors.red,
                ),
                title: Text(
                  irAvailable == null
                      ? 'Checking IR availability...'
                      : irAvailable!
                      ? 'IR Transmitter Available'
                      : 'IR Transmitter Not Available',
                ),
                subtitle: irAvailable == false
                    ? const Text('This device does not have an IR blaster')
                    : null,
              ),
              if (supportedProtocols != null &&
                  supportedProtocols!.isNotEmpty) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Supported Protocols:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: supportedProtocols!
                            .map(
                              (protocol) => Chip(
                                label: Text(protocol),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: irAvailable == true
                          ? _testIRTransmitter
                          : null,
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Test IR'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _checkIRCapabilities,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Feedback
        Card(
          child: SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Vibrate when pressing buttons'),
            value: enableVibration,
            onChanged: (value) => setState(() => enableVibration = value),
          ),
        ),

        const SizedBox(height: 16),

        // Updates
        Card(
          child: ListTile(
            leading: Icon(
              _checkingUpdate ? Icons.sync : Icons.system_update,
              color: const Color(0xFFFF8C00),
            ),
            title: Text(
              _checkingUpdate ? 'Checking for updates…' : 'Check for updates',
            ),
            subtitle: Text(
              _version == null
                  ? 'Current version'
                  : 'Version ${_version!.versionName} '
                        '(${_version!.versionCode})',
            ),
            trailing: _checkingUpdate
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _checkingUpdate ? null : _checkForUpdates,
          ),
        ),

        const SizedBox(height: 16),

        // IR Settings
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Test IR Transmitter'),
                leading: const Icon(Icons.wifi_protected_setup),
                onTap: _testIRTransmitter,
              ),
              ListTile(
                title: const Text('About'),
                leading: const Icon(Icons.info),
                onTap: _showAboutDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _testIRTransmitter() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              SizedBox(width: 12),
              Text('Testing IR transmitter...'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      // Test with a basic NEC power signal
      await IRTransmitter.transmit(0x20DF10EF); // Common power off code

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.onTertiary,
                size: 16,
              ),
              SizedBox(width: 12),
              Text('IR test completed successfully'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error,
                color: Theme.of(context).colorScheme.onError,
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'IR test failed: ${e.toString().replaceAll('Exception: ', '')}',
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showAboutDialog() {
    final version = _version?.versionName ?? 'Unknown';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('IReDroid'),
        content: Text(
          'Lightweight IR remote control app\n\n'
          'Version: $version\n'
          'Supports Flipper Zero .ir files and many IR protocols\n\n'
          'Made by 0x1c1101 (aka heapsoverflow)\n'
          'With <3',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
