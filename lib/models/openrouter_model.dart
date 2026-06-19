/// Metadata for a model available through OpenRouter, as returned by the
/// `GET /api/v1/models` endpoint.
class OpenRouterModel {
  OpenRouterModel({
    required this.id,
    required this.name,
    this.description,
    this.contextLength,
    this.maxOutputTokens,
    this.promptPrice,
    this.completionPrice,
    this.created,
    this.inputModalities = const ['text'],
    this.outputModalities = const ['text'],
    this.supportedParameters = const [],
  });

  /// The fully-qualified id used in requests, e.g. `openai/gpt-4o-mini`.
  final String id;
  final String name;
  final String? description;
  final int? contextLength;

  /// Maximum number of completion (output) tokens the top provider allows.
  final int? maxOutputTokens;

  /// Price per token (USD) for prompt / completion tokens.
  final double? promptPrice;
  final double? completionPrice;

  /// When the model was added to OpenRouter.
  final DateTime? created;

  /// Modalities the model accepts / produces, e.g. `['text', 'image']`.
  final List<String> inputModalities;
  final List<String> outputModalities;

  /// Request parameters the model supports, e.g. `tools`, `response_format`,
  /// `reasoning`. Used to derive capability flags.
  final List<String> supportedParameters;

  bool get isFree => (promptPrice ?? 0) == 0 && (completionPrice ?? 0) == 0;

  /// The vendor segment of the id, e.g. `openai` for `openai/gpt-4o-mini`.
  String get vendor => id.contains('/') ? id.split('/').first : 'other';

  bool get supportsImageInput => inputModalities.contains('image');
  bool get supportsImageOutput => outputModalities.contains('image');

  /// Per-million-token prices (USD), the unit shown in the UI.
  double? get promptPricePerM =>
      promptPrice == null ? null : promptPrice! * 1000000;
  double? get completionPricePerM =>
      completionPrice == null ? null : completionPrice! * 1000000;

  // Capability flags derived from supported parameters / modalities.
  bool get supportsTools => supportedParameters.contains('tools');
  bool get supportsJsonOutput =>
      supportedParameters.contains('response_format') ||
      supportedParameters.contains('structured_outputs');
  bool get supportsReasoning =>
      supportedParameters.contains('reasoning') ||
      supportedParameters.contains('include_reasoning');
  bool get isMultimodal => supportsImageInput;

  /// Whether the model was added within the given recency window.
  bool isNewerThan(Duration window) {
    final c = created;
    if (c == null) return false;
    return DateTime.now().difference(c) <= window;
  }

  factory OpenRouterModel.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'] as Map<String, dynamic>?;
    double? parsePrice(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());

    final arch = json['architecture'] as Map<String, dynamic>?;
    List<String> strings(dynamic v) =>
        (v as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];
    List<String> modalities(dynamic v) {
      final list = strings(v);
      return list.isEmpty ? const ['text'] : list;
    }

    final topProvider = json['top_provider'] as Map<String, dynamic>?;
    final createdSecs = (json['created'] as num?)?.toInt();

    final rawName = (json['name'] as String?)?.trim();
    return OpenRouterModel(
      id: json['id'] as String,
      name:
          rawName != null && rawName.isNotEmpty ? rawName : json['id'] as String,
      description: json['description'] as String?,
      contextLength: (json['context_length'] as num?)?.toInt(),
      maxOutputTokens: (topProvider?['max_completion_tokens'] as num?)?.toInt(),
      promptPrice: parsePrice(pricing?['prompt']),
      completionPrice: parsePrice(pricing?['completion']),
      created: createdSecs != null
          ? DateTime.fromMillisecondsSinceEpoch(createdSecs * 1000)
          : null,
      inputModalities: modalities(arch?['input_modalities']),
      outputModalities: modalities(arch?['output_modalities']),
      supportedParameters: strings(json['supported_parameters']),
    );
  }
}
