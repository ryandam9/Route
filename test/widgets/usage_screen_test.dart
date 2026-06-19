import 'package:auris/auris.dart';
import 'package:auris/auris_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:route/models/usage.dart';
import 'package:route/providers/usage_provider.dart';
import 'package:route/screens/usage_screen.dart';

import '../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders session totals, balance and per-model breakdown',
      (tester) async {
    late UsageProvider usage;
    await tester.runAsync(() async {
      final settings = await buildLoadedSettings();
      final service = FakeOpenRouterService()
        ..credits = const CreditBalance(totalCredits: 5, totalUsage: 2);
      usage = UsageProvider(service: service, settings: settings);
      usage.record(
        'openai/gpt-4o',
        const TokenUsage(promptTokens: 100, completionTokens: 40, cost: 0.01),
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AurisTheme.dark(),
        home: ChangeNotifierProvider<UsageProvider>.value(
          value: usage,
          child: const UsageScreen(),
        ),
      ),
    );
    // Let the post-frame credit fetch resolve.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('Session usage'), findsOneWidget);
    // Input / output / cost / requests.
    expect(find.byType(AurisStatCard), findsNWidgets(4));
    expect(find.text('openai/gpt-4o'), findsOneWidget);
    // AurisDataRow renders labels uppercase.
    expect(find.text('REMAINING'), findsOneWidget);
  });
}
