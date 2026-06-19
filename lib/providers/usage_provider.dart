import 'package:flutter/foundation.dart';

import '../models/usage.dart';
import '../services/openrouter_service.dart';
import 'settings_provider.dart';

/// Tracks OpenRouter usage for the current app session (in-memory; resets on
/// restart). Also fetches the account-level credit balance on demand.
class UsageProvider extends ChangeNotifier {
  UsageProvider({
    required OpenRouterService service,
    required SettingsProvider settings,
  })  : _service = service,
        _settings = settings;

  final OpenRouterService _service;
  final SettingsProvider _settings;

  int _promptTokens = 0;
  int _completionTokens = 0;
  double _cost = 0;
  int _requests = 0;
  final Map<String, ModelUsage> _byModel = {};

  CreditBalance? _credits;
  bool _creditsLoading = false;
  String? _creditsError;

  int get promptTokens => _promptTokens;
  int get completionTokens => _completionTokens;
  int get totalTokens => _promptTokens + _completionTokens;
  double get cost => _cost;
  int get requests => _requests;
  bool get isEmpty => _requests == 0;

  /// Per-model breakdown, sorted by cost (then tokens) descending.
  List<ModelUsage> get byModel {
    final list = _byModel.values.toList();
    list.sort((a, b) {
      final byCost = b.cost.compareTo(a.cost);
      return byCost != 0 ? byCost : b.totalTokens.compareTo(a.totalTokens);
    });
    return list;
  }

  CreditBalance? get credits => _credits;
  bool get creditsLoading => _creditsLoading;
  String? get creditsError => _creditsError;

  /// Records the usage of one completion against [modelId].
  void record(String modelId, TokenUsage usage) {
    _promptTokens += usage.promptTokens;
    _completionTokens += usage.completionTokens;
    _cost += usage.cost;
    _requests++;
    _byModel.putIfAbsent(modelId, () => ModelUsage(modelId)).add(usage);
    notifyListeners();
  }

  /// Clears all session totals.
  void reset() {
    _promptTokens = 0;
    _completionTokens = 0;
    _cost = 0;
    _requests = 0;
    _byModel.clear();
    notifyListeners();
  }

  /// Fetches the account credit balance. Errors (e.g. a key without credit
  /// permissions) are captured in [creditsError] rather than thrown.
  Future<void> refreshCredits() async {
    final key = _settings.apiKey;
    if (key == null || key.isEmpty) {
      _creditsError = 'Add your API key in Settings first.';
      notifyListeners();
      return;
    }
    _creditsLoading = true;
    _creditsError = null;
    notifyListeners();
    try {
      _credits = await _service.fetchCredits(key);
    } catch (e) {
      _creditsError = e.toString();
    } finally {
      _creditsLoading = false;
      notifyListeners();
    }
  }
}
