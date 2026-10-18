import 'package:flutter/material.dart';

import '../services/remote_store.dart';

enum AddRemoteAction { flipper, create, importFile, fuzzer, voltas, atomberg }

/// Premium bottom sheet shown when the user adds a remote.
class AddRemoteSheet extends StatelessWidget {
  const AddRemoteSheet({super.key, required this.addedBuiltins});

  final Set<String> addedBuiltins;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF151517),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add a remote',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bring in a remote or discover one with the fuzzer.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.18,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _ActionTile(
                    icon: Icons.cloud_download_outlined,
                    title: 'Flipper IRDB',
                    subtitle: '1700+ devices',
                    accent: const Color(0xFFFF8C00),
                    onTap: () =>
                        Navigator.pop(context, AddRemoteAction.flipper),
                  ),
                  _ActionTile(
                    icon: Icons.add_circle_outline,
                    title: 'Create remote',
                    subtitle: 'Build it yourself',
                    accent: const Color(0xFF7DD3FC),
                    onTap: () => Navigator.pop(context, AddRemoteAction.create),
                  ),
                  _ActionTile(
                    icon: Icons.file_upload_outlined,
                    title: 'Import file',
                    subtitle: '.ir files supported',
                    accent: const Color(0xFF86EFAC),
                    onTap: () =>
                        Navigator.pop(context, AddRemoteAction.importFile),
                  ),
                  _ActionTile(
                    icon: Icons.shuffle,
                    title: 'IR Fuzzer',
                    subtitle: 'Find a working code',
                    accent: const Color(0xFFC4B5FD),
                    onTap: () => Navigator.pop(context, AddRemoteAction.fuzzer),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'BUILT-IN REMOTES',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.4,
                  color: Colors.white38,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _BuiltinTile(
                icon: Icons.ac_unit,
                title: 'Voltas AC',
                subtitle: 'Smart AC control with 11 code varieties',
                added: addedBuiltins.contains(RemoteStore.builtinVoltas),
                onTap: () => Navigator.pop(context, AddRemoteAction.voltas),
              ),
              const SizedBox(height: 8),
              _BuiltinTile(
                icon: Icons.toys,
                title: 'Atomberg Fan',
                subtitle: 'Power, speeds, Boost, Timer, LED and Sleep',
                added: addedBuiltins.contains(RemoteStore.builtinAtomberg),
                onTap: () => Navigator.pop(context, AddRemoteAction.atomberg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.16),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
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
}

class _BuiltinTile extends StatelessWidget {
  const _BuiltinTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.added,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1D1D20),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: added ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFF8C00), size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              added
                  ? const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: Color(0xFF86EFAC),
                    )
                  : const Icon(
                      Icons.add_circle_outline,
                      size: 20,
                      color: Colors.white38,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
