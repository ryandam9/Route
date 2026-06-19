import 'package:auris/auris.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:route/providers/settings_provider.dart';
import 'package:route/screens/settings_screen.dart';

import '../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders all panels (incl. font rows) without layout errors',
      (tester) async {
    // A tall surface so the lazy ListView builds every panel, including Fonts.
    await tester.binding.setSurfaceSize(const Size(1200, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late SettingsProvider settings;
    await tester.runAsync(() async {
      settings = await buildLoadedSettings();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AurisTheme.dark(),
        home: ChangeNotifierProvider<SettingsProvider>.value(
          value: settings,
          child: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    // The font-picker Row previously threw a RenderFlex unbounded-width error.
    expect(tester.takeException(), isNull);
    expect(find.text('HEADING'), findsOneWidget);
    // Heading defaults to Rajdhani; its button shows the label.
    expect(find.text('Rajdhani'), findsWidgets);
  });
}
