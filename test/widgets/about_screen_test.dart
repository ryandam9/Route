import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wombat/build_info.dart';
import 'package:wombat/screens/about_screen.dart';

void main() {
  testWidgets('About screen shows app details and the build commit',
      (tester) async {
    // A tall viewport so every panel in the scrolling list is laid out.
    tester.view.physicalSize = const Size(1000, 3400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    await tester.pumpAndSettle();

    // App identity.
    expect(find.text('Wombat'), findsOneWidget);
    expect(find.text('About'), findsWidgets); // app bar title

    // The version leads with the git commit (badge + Build panel row).
    expect(find.textContaining(BuildInfo.commit), findsWidgets);

    // Content anchors from the detail sections.
    expect(find.text('Streaming chat'), findsOneWidget);
    expect(find.text('Source code on GitHub'), findsOneWidget);
  });
}
