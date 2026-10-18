import 'package:flutter/material.dart';

import 'flipper_tab.dart';

/// Full page Flipper IRDB browser, launched from Add Remote.
class FlipperBrowserScreen extends StatelessWidget {
  const FlipperBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flipper IRDB',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: const FlipperTab(),
    );
  }
}
