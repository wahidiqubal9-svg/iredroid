import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/ir_device.dart';
import '../services/remote_store.dart';
import '../services/update_manager.dart';
import '../utils/haptics.dart';
import '../utils/ir_file_parser.dart';
import '../utils/voltas_prefs.dart';
import '../widgets/add_remote_sheet.dart';
import '../widgets/mini_remote.dart';
import '../widgets/update_prompt.dart';
import 'atomberg_remote_screen.dart';
import 'flipper_browser_screen.dart';
import 'fuzzer_screen.dart';
import 'full_screen_ir_remote.dart';
import 'remote_editor_screen.dart';
import 'settings_screen.dart';
import 'voltas_remote_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SavedRemote> _remotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoCheckForUpdates());
  }

  Future<void> _autoCheckForUpdates() async {
    try {
      if (!await UpdateManager.shouldAutoCheck()) return;
      await UpdateManager.markChecked();
      final update = await UpdateManager.check();
      if (!mounted || update == null) return;
      await showUpdatePrompt(context, update);
    } catch (_) {
      // Silent: updates should never block using the app.
    }
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner && mounted) {
      setState(() => _loading = true);
    }
    final remotes = await RemoteStore.loadAll();
    if (!mounted) return;
    setState(() {
      _remotes = remotes;
      _loading = false;
    });
  }

  Set<String> get _addedBuiltins => _remotes
      .where((remote) => remote.builtinId != null)
      .map((remote) => remote.builtinId!)
      .toSet();

  Future<void> _openAddSheet() async {
    Haptics.tap();
    final action = await showModalBottomSheet<AddRemoteAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRemoteSheet(addedBuiltins: _addedBuiltins),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case AddRemoteAction.flipper:
        await _browseFlipper();
        break;
      case AddRemoteAction.create:
        await _createRemote();
        break;
      case AddRemoteAction.importFile:
        await _importRemote();
        break;
      case AddRemoteAction.fuzzer:
        await _openFuzzer();
        break;
      case AddRemoteAction.voltas:
        await _addBuiltin(RemoteStore.builtinVoltas);
        break;
      case AddRemoteAction.atomberg:
        await _addBuiltin(RemoteStore.builtinAtomberg);
        break;
    }
  }

  Future<void> _addBuiltin(String id) async {
    final added = await RemoteStore.addBuiltin(id);
    await _load(showSpinner: false);
    if (!mounted) return;
    final name = id == RemoteStore.builtinVoltas ? 'Voltas AC' : 'Atomberg Fan';
    _toast(added ? '$name added' : '$name is already on your home');
  }

  Future<void> _browseFlipper() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FlipperBrowserScreen()),
    );
    if (mounted) await _load(showSpinner: false);
  }

  Future<void> _openFuzzer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FuzzerScreen()),
    );
    if (mounted) await _load(showSpinner: false);
  }

  Future<void> _createRemote() async {
    final device = await Navigator.push<IRDevice>(
      context,
      MaterialPageRoute(builder: (_) => const CustomRemoteEditor()),
    );
    if (device == null || !mounted) return;
    await RemoteStore.saveDevice(device, source: 'Created in app');
    await _load(showSpinner: false);
    if (!mounted) return;
    _toast('${device.name} added');
  }

  Future<void> _importRemote() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      final picked = result?.files.single;
      final path = picked?.path;
      if (picked == null || path == null) return;

      final content = await File(path).readAsString();
      if (!IRFileParser.isValidIRFile(content)) {
        if (mounted) {
          _toast('That file does not look like a valid .ir file');
        }
        return;
      }

      final fallbackName = picked.name.replaceAll(
        RegExp(r'\.ir$', caseSensitive: false),
        '',
      );
      final device = IRFileParser.parseIRFileContent(content, fallbackName);
      if (device == null || device.buttons.isEmpty) {
        if (mounted) {
          _toast('No usable buttons were found in that file');
        }
        return;
      }

      await RemoteStore.saveDevice(device, source: 'Imported file');
      await _load(showSpinner: false);
      if (!mounted) return;
      _toast('${device.name} imported');
    } catch (error) {
      if (mounted) {
        _toast('Import failed: $error');
      }
    }
  }

  Future<void> _openRemote(SavedRemote remote) async {
    Haptics.tap();
    final device = remote.device;
    final Widget screen;
    switch (remote.builtinId) {
      case RemoteStore.builtinVoltas:
        screen = const VoltasRemoteScreen();
        break;
      case RemoteStore.builtinAtomberg:
        screen = const AtombergRemoteScreen();
        break;
      default:
        screen = FullScreenIRRemote(device: device);
        break;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _load(showSpinner: false);
  }

  Future<void> _showRemoteActions(SavedRemote remote) async {
    Haptics.select();
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF151517),
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Open remote'),
              onTap: () => Navigator.pop(context, 'open'),
            ),
            if (remote.isFileBacked)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit remote'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
            if (remote.builtinId == RemoteStore.builtinVoltas)
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Change AC code'),
                onTap: () => Navigator.pop(context, 'variety'),
              ),
            ListTile(
              leading: Icon(
                remote.isBuiltin
                    ? Icons.remove_circle_outline
                    : Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                remote.isBuiltin ? 'Remove from home' : 'Delete remote',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case 'open':
        await _openRemote(remote);
        break;
      case 'edit':
        await _editRemote(remote);
        break;
      case 'variety':
        await _pickVoltasVariety();
        break;
      case 'delete':
        await _deleteRemote(remote);
        break;
    }
  }

  Future<void> _editRemote(SavedRemote remote) async {
    final device = await Navigator.push<IRDevice>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomRemoteEditor(device: remote.device),
      ),
    );
    if (device == null || !mounted) return;
    await RemoteStore.updateDevice(remote, device, source: 'Edited in app');
    await _load(showSpinner: false);
    if (!mounted) return;
    _toast('${device.name} updated');
  }

  Future<void> _deleteRemote(SavedRemote remote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(remote.isBuiltin ? 'Remove remote?' : 'Delete remote?'),
        content: Text(
          remote.isBuiltin
              ? '${remote.device.name} will be removed from your home screen. '
                    'You can add it again at any time.'
              : '${remote.device.name} will be permanently deleted from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              remote.isBuiltin ? 'Remove' : 'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await RemoteStore.delete(remote);
    await _load(showSpinner: false);
    if (!mounted) return;
    _toast('${remote.device.name} removed');
  }

  Future<void> _pickVoltasVariety() async {
    final current = await VoltasPrefs.getVariety();
    if (!mounted) return;
    final chosen = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF151517),
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Which Voltas remote works for your AC?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...List.generate(
              VoltasPrefs.varietyCount,
              (index) => ListTile(
                title: Text('Remote ${index + 1}'),
                trailing: index + 1 == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, index + 1),
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await VoltasPrefs.setVariety(chosen);
    if (mounted) _toast('Using Voltas remote $chosen');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Remotes',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 10),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Add remote',
            icon: const Icon(Icons.add, size: 28),
            onPressed: _openAddSheet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _remotes.isEmpty
          ? _EmptyHome(onAdd: _openAddSheet)
          : RefreshIndicator(
              onRefresh: () => _load(showSpinner: false),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 700 ? 3 : 2;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: _remotes.length,
                    itemBuilder: (context, index) {
                      final remote = _remotes[index];
                      return _RemoteCard(
                        remote: remote,
                        onTap: () => _openRemote(remote),
                        onLongPress: () => _showRemoteActions(remote),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onAdd,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF8C00).withValues(alpha: 0.24),
                      const Color(0xFFFF8C00).withValues(alpha: 0.02),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFFF8C00).withValues(alpha: 0.24),
                  ),
                ),
                child: const Icon(
                  Icons.settings_remote,
                  size: 56,
                  color: Color(0xFFFF8C00),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Your remotes, one tap away',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Add a remote from the Flipper database, create one yourself, '
                'import an .ir file, or discover one with the fuzzer.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add your first remote'),
              ),
              const SizedBox(height: 12),
              Text(
                'or tap the + button in the top corner',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoteCard extends StatelessWidget {
  const _RemoteCard({
    required this.remote,
    required this.onTap,
    required this.onLongPress,
  });

  final SavedRemote remote;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final device = remote.device;
    final isVoltas = remote.builtinId == RemoteStore.builtinVoltas;
    final subtitle = remote.isBuiltin
        ? 'Smart remote'
        : '${device.brand} · ${device.buttons.length} buttons';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: remote.isBuiltin
                  ? [
                      const Color(0xFFFF8C00).withValues(alpha: 0.18),
                      const Color(0xFF1B1B1E),
                    ]
                  : [const Color(0xFF242428), const Color(0xFF161619)],
            ),
            border: Border.all(
              color: remote.isBuiltin
                  ? const Color(0xFFFF8C00).withValues(alpha: 0.28)
                  : Colors.white12,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MiniRemotePreview(
                    digital: isVoltas,
                    icon: isVoltas ? null : _iconFor(device.category),
                  ),
                  const Spacer(),
                  if (remote.isBuiltin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C00).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'BUILT-IN',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 0.7,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF8C00),
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Colors.white38,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                device.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
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
