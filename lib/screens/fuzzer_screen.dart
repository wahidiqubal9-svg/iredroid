import 'package:flutter/material.dart';

import 'fuzzer_tab.dart';

/// Full page wrapper for the IR fuzzer, launched from Add Remote.
class FuzzerScreen extends StatelessWidget {
  const FuzzerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Auto Detect',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: const FuzzerTab(),
    );
  }
}
