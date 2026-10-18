import 'dart:async';

import 'package:flutter/material.dart';

import '../services/update_manager.dart';

/// Shows the update dialog and, if accepted, downloads and launches the
/// Android installer.
Future<void> showUpdatePrompt(BuildContext context, AppUpdate update) async {
  final install = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Update available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IReDroid ${update.versionName} is ready to install.'),
          if (update.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              update.notes,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Install now'),
        ),
      ],
    ),
  );

  if (install == true && context.mounted) {
    await installUpdate(context, update);
  }
}

Future<void> installUpdate(BuildContext context, AppUpdate update) async {
  if (await UpdateManager.needsInstallPermission()) {
    await UpdateManager.openInstallPermissionSettings();
    if (context.mounted) {
      _snack(
        context,
        'Allow installs for IReDroid, then tap Check for updates again.',
      );
    }
    return;
  }

  final navigator = Navigator.of(context, rootNavigator: true);
  var progressOpen = true;
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text('Downloading update…'),
          content: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 16),
              Expanded(child: Text('Please keep the app open.')),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    final file = await UpdateManager.download(update);
    if (progressOpen && navigator.canPop()) {
      navigator.pop();
    }
    progressOpen = false;
    if (!context.mounted) return;

    final opened = await UpdateManager.install(file);
    if (!opened) {
      _snack(context, 'Could not open the Android installer.');
    }
  } catch (error) {
    if (progressOpen && navigator.canPop()) {
      navigator.pop();
    }
    progressOpen = false;
    if (context.mounted) {
      _snack(context, 'Update failed: $error');
    }
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
