import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'flipper_tab.dart';

/// Full page Flipper IRDB browser, launched from Add Remote.
class FlipperBrowserScreen extends StatelessWidget {
  const FlipperBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Remote Library',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Image credits',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showImageCredits(context),
          ),
        ],
      ),
      body: const FlipperTab(),
    );
  }

  Future<void> _showImageCredits(BuildContext context) async {
    String text;
    try {
      text = await rootBundle.loadString('assets/device_images/ATTRIBUTION.md');
    } catch (_) {
      text = 'Device photos are from Wikimedia Commons.';
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device image credits'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
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
