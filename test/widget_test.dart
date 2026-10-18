import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iredroid/main.dart';

void main() {
  testWidgets('home shows the add-remote empty state', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('My Remotes'), findsOneWidget);
    expect(find.text('Add your first remote'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsWidgets);
  });
}
