/// Token counts and cost for a single OpenRouter completion, parsed from the
/// `usage` object OpenRouter includes in the final response/stream chunk.
class TokenUsage {
  const TokenUsage({
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.cost = 0,
  });

  final int promptTokens;
  final int completionTokens;

  /// Cost of the request in US dollars (OpenRouter's `cost` field).
  final double cost;

  int get totalTokens => promptTokens + completionTokens;

  factory TokenUsage.fromJson(Map<String, dynamic> json) => TokenUsage(
        promptTokens: (json['prompt_tokens'] as num?)?.toInt() ?? 0,
        completionTokens: (json['completion_tokens'] as num?)?.toInt() ?? 0,
        cost: (json['cost'] as num?)?.toDouble() ?? 0,
      );
}

/// Mutable per-model accumulator for the session usage breakdown.
class ModelUsage {
  ModelUsage(this.modelId);

  final String modelId;
  int promptTokens = 0;
  int completionTokens = 0;
  double cost = 0;
  int requests = 0;

  int get totalTokens => promptTokens + completionTokens;

  void add(TokenUsage usage) {
    promptTokens += usage.promptTokens;
    completionTokens += usage.completionTokens;
    cost += usage.cost;
    requests++;
  }
}

/// Account-level credit balance from `GET /api/v1/credits`.
class CreditBalance {
  const CreditBalance({required this.totalCredits, required this.totalUsage});

  final double totalCredits;
  final double totalUsage;

  double get remaining => totalCredits - totalUsage;

  factory CreditBalance.fromJson(Map<String, dynamic> json) => CreditBalance(
        totalCredits: (json['total_credits'] as num?)?.toDouble() ?? 0,
        totalUsage: (json['total_usage'] as num?)?.toDouble() ?? 0,
      );
}
