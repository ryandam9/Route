import 'package:flutter/material.dart';

/// Material 3 light/dark themes for the app.
///
/// The dark theme is generated straight from the brand seed. The light theme is
/// hand-tuned on top of the seed palette for a cleaner, more modern look:
/// crisp cool-white layered surfaces, a punchier indigo-violet brand colour,
/// and a teal accent — instead of the flat, washed-out default light surfaces.
class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF6750A4);

  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark =>
      _build(ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark));

  /// Bespoke light scheme: starts from the seed palette, then refines the brand
  /// colour, the accent (tertiary), the surface ramp and the outlines.
  static final ColorScheme _lightScheme =
      ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light)
          .copyWith(
    // A more vivid indigo-violet so primary actions and accents pop.
    primary: const Color(0xFF5A4FCF),
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFE6E0FF),
    onPrimaryContainer: const Color(0xFF170E4A),
    // Teal accent for chips, highlights and the model border gradient.
    tertiary: const Color(0xFF1C8C81),
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFB6F1E7),
    onTertiaryContainer: const Color(0xFF00201C),
    // Cool, slightly tinted whites with a clear elevation ramp for depth.
    surface: const Color(0xFFFCFBFF),
    onSurface: const Color(0xFF1B1B23),
    onSurfaceVariant: const Color(0xFF45454F),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF6F4FC),
    surfaceContainer: const Color(0xFFF0EEF8),
    surfaceContainerHigh: const Color(0xFFEAE8F3),
    surfaceContainerHighest: const Color(0xFFE4E2EE),
    // Softer, crisper hairlines.
    outline: const Color(0xFF77757F),
    outlineVariant: const Color(0xFFCAC7D3),
  );

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
    );
  }
}
