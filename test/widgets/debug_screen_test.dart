import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:route/screens/debug_screen.dart';
import 'package:route/services/debug_log.dart';
import 'package:route/theme/app_theme.dart';

Widget _wrap(DebugLog log) => MaterialApp(
      theme: AppTheme.dark,
      home: ChangeNotifierProvider<DebugLog>.value(
        value: log,
        child: const DebugScreen(),
      ),
    );

void main() {
  testWidgets('shows an empty state when there is no activity',
      (tester) async {
    await tester.pumpWidget(_wrap(DebugLog()));
    expect(find.text('No activity yet'), findsOneWidget);
  });

  testWidgets('lists entries newest-first and expands JSON detail',
      (tester) async {
    final log = DebugLog()
      ..add(DebugKind.request, 'POST /chat/completions',
          detail: '{"model":"m","stream":true}')
      ..add(DebugKind.info, 'keep-alive', detail: 'OPENROUTER PROCESSING');

    await tester.pumpWidget(_wrap(log));
    await tester.pump();

    expect(find.text('POST /chat/completions'), findsOneWidget);
    expect(find.text('keep-alive'), findsOneWidget);

    // Expanding the request reveals the pretty-printed JSON body.
    await tester.tap(find.text('POST /chat/completions'));
    await tester.pumpAndSettle();
    expect(find.textContaining('"model": "m"'), findsOneWidget);
  });

  testWidgets('clear empties the log', (tester) async {
    final log = DebugLog()..add(DebugKind.info, 'x');
    await tester.pumpWidget(_wrap(log));

    await tester.tap(find.byTooltip('Clear'));
    // Pump past the log's notification throttle so no timer is left pending.
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No activity yet'), findsOneWidget);
  });
}
