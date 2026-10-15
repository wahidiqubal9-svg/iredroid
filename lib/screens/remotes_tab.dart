import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/ir_device.dart';
import '../utils/ir_file_parser.dart';
import 'full_screen_ir_remote.dart';
import 'voltas_remote_screen.dart';

/// A single place that lists every saved remote: built-in smart remotes
/// (Voltas AC) and any remotes the user saved (favorites / custom).
/// Tapping one opens it full-screen; pinch in with two fingers to close.
class RemotesTab extends StatefulWidget {
  const RemotesTab({super.key});

  @override
  State<RemotesTab> createState() => _RemotesTabState();
}

class _RemotesTabState extends State<RemotesTab> {
  List<IRDevice> _saved = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final devices = <IRDevice>[];
    try {
      final dir = await getApplicationDocumentsDirectory();
      final customDir = Directory('${dir.path}/Custom');
      if (await customDir.exists()) {
        final files = customDir
            .listSync()
            .where((f) => f.path.endsWith('.ir'))
            .toList();
        for (final file in files) {
          try {
            final content = await File(file.path).readAsString();
            final device = IRFileParser.parseIRFileContent(content);
            if (device != null && device.buttons.isNotEmpty) {
              devices.add(device);
            }
          } catch (_) {
            // skip unreadable files
          }
        }
      }
    } catch (_) {
      // no saved remotes
    }
    if (!mounted) return;
    setState(() {
      _saved = devices;
      _loading = false;
    });
  }

  void _openVoltas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VoltasRemoteScreen()),
    );
  }

  void _openDevice(IRDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FullScreenIRRemote(device: device)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('My Remotes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('All your saved remotes in one place',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          _sectionTitle('Smart remotes'),
          _remoteCard(
            icon: Icons.ac_unit,
            title: 'Voltas AC',
            subtitle: 'Full AC control · 11 varieties',
            onTap: _openVoltas,
          ),
          const SizedBox(height: 20),
          _sectionTitle('Saved remotes'),
          if (_saved.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No saved remotes yet.\nSave one from the Flipper tab (★) or create one in the Custom tab.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._saved.map(
              (device) => _remoteCard(
                icon: _iconFor(device.category),
                title: device.name,
                subtitle: '${device.category} · ${device.buttons.length} buttons',
                onTap: () => _openDevice(device),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontSize: 12, letterSpacing: 1.5, color: Colors.white54),
      ),
    );
  }

  Widget _remoteCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon,
            size: 28, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
