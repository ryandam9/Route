import 'package:flutter_test/flutter_test.dart';
import 'package:route/models/usage.dart';
import 'package:route/providers/usage_provider.dart';

import '../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<UsageProvider> build(FakeOpenRouterService service) async {
    final settings = await buildLoadedSettings();
    return UsageProvider(service: service, settings: settings);
  }

  test('record accumulates totals and per-model breakdown', () async {
    final usage = await build(FakeOpenRouterService());

    usage.record('a/one',
        const TokenUsage(promptTokens: 10, completionTokens: 5, cost: 0.001));
    usage.record('a/one',
        const TokenUsage(promptTokens: 2, completionTokens: 1, cost: 0.0005));
    usage.record('b/two',
        const TokenUsage(promptTokens: 100, completionTokens: 50, cost: 0.02));

    expect(usage.promptTokens, 112);
    expect(usage.completionTokens, 56);
    expect(usage.totalTokens, 168);
    expect(usage.requests, 3);
    expect(usage.cost, closeTo(0.0215, 1e-9));
    expect(usage.isEmpty, isFalse);

    // Sorted by cost descending: b/two first.
    expect(usage.byModel.first.modelId, 'b/two');
    expect(usage.byModel.firstWhere((m) => m.modelId == 'a/one').requests, 2);
  });

  test('reset clears all totals', () async {
    final usage = await build(FakeOpenRouterService());
    usage.record('a/one', const TokenUsage(promptTokens: 1, cost: 0.1));
    usage.reset();

    expect(usage.isEmpty, isTrue);
    expect(usage.totalTokens, 0);
    expect(usage.cost, 0);
    expect(usage.byModel, isEmpty);
  });

  test('refreshCredits loads the balance on success', () async {
    final service = FakeOpenRouterService()
      ..credits = const CreditBalance(totalCredits: 10, totalUsage: 4);
    final usage = await build(service);

    await usage.refreshCredits();

    expect(usage.credits?.remaining, 6);
    expect(usage.creditsError, isNull);
    expect(usage.creditsLoading, isFalse);
  });

  test('refreshCredits captures errors instead of throwing', () async {
    final service = FakeOpenRouterService()..creditsError = Exception('403');
    final usage = await build(service);

    await usage.refreshCredits();

    expect(usage.credits, isNull);
    expect(usage.creditsError, contains('403'));
    expect(usage.creditsLoading, isFalse);
  });

  test('refreshCredits requires an API key', () async {
    final settings = await buildLoadedSettings(apiKey: null);
    final usage =
        UsageProvider(service: FakeOpenRouterService(), settings: settings);

    await usage.refreshCredits();

    expect(usage.creditsError, contains('API key'));
  });
}
