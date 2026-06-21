import 'package:flutter/material.dart';

/// A stable, vivid accent colour for a model, derived from its id. Used to give
/// each model a persistent visual identity — the ambient backdrop tint, the
/// assistant orb avatar, and message accents — so a multi-model app feels
/// alive and each turn is distinguishable at a glance.
///
/// The palette is tuned for vibrancy and pairs well with the brand violet:
/// each colour is saturated and leans cool/warm so different models read
/// distinctly. The same id always yields the same colour.
class ModelColor {
  ModelColor._();

  static const _palette = <Color>[
    Color(0xFF6D4AFF), // brand violet
    Color(0xFF00B8D4), // cyan
    Color(0xFF2E9E5B), // green
    Color(0xFFE08A00), // amber
    Color(0xFFE0518A), // pink
    Color(0xFF9C5BE0), // purple
    Color(0xFF2196F3), // blue
    Color(0xFF00ACC1), // teal
    Color(0xFFEF5350), // red
    Color(0xFF7E57C2), // deep purple
  ];

  /// A vivid colour for [modelId]. Falls back to the brand violet when null.
  static Color forModel(String? modelId) {
    final t = modelId?.trim() ?? '';
    if (t.isEmpty) return _palette.first;
    return _palette[t.hashCode.abs() % _palette.length];
  }

  /// A soft, harmonised secondary tint (for gradient endpoints): rotates the
  /// hue ~40° while keeping lightness/saturation, so it always pairs.
  static Color companion(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withHue((hsl.hue + 38) % 360)
        .withSaturation((hsl.saturation + 0.05).clamp(0.0, 1.0))
        .toColor();
  }
}
