import 'package:flutter_test/flutter_test.dart';
import 'package:wombat/models/usage.dart';

void main() {
  group('TokenUsage', () {
    test('parses fields and computes total', () {
      final usage = TokenUsage.fromJson({
        'prompt_tokens': 12,
        'completion_tokens': 8,
        'cost': 0.0123,
      });
      expect(usage.promptTokens, 12);
      expect(usage.completionTokens, 8);
      expect(usage.totalTokens, 20);
      expect(usage.cost, 0.0123);
    });

    test('defaults missing fields to zero', () {
      final usage = TokenUsage.fromJson({});
      expect(usage.promptTokens, 0);
      expect(usage.completionTokens, 0);
      expect(usage.cost, 0);
    });
  });

  group('ModelUsage', () {
    test('accumulates multiple usages', () {
      final m = ModelUsage('openai/gpt-4o')
        ..add(const TokenUsage(promptTokens: 10, completionTokens: 5, cost: 1))
        ..add(const TokenUsage(promptTokens: 4, completionTokens: 1, cost: 0.5));
      expect(m.promptTokens, 14);
      expect(m.completionTokens, 6);
      expect(m.totalTokens, 20);
      expect(m.cost, 1.5);
      expect(m.requests, 2);
    });
  });

  group('CreditBalance', () {
    test('parses and computes remaining', () {
      final c = CreditBalance.fromJson({'total_credits': 10, 'total_usage': 3});
      expect(c.totalCredits, 10);
      expect(c.totalUsage, 3);
      expect(c.remaining, 7);
    });

    test('defaults missing fields to zero', () {
      final c = CreditBalance.fromJson({});
      expect(c.totalCredits, 0);
      expect(c.remaining, 0);
    });
  });
}
