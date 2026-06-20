import 'package:flutter/material.dart';

/// Material 3 light/dark themes for the app.
///
/// Both themes are generated from an accent ("seed") colour. The dark theme is
/// taken straight from the seed palette; the light theme is refined on top for
/// a cleaner, more modern look — crisp cool-white layered surfaces and softer
/// outlines — instead of the flat, washed-out default light surfaces.
///
/// The seed defaults to [defaultSeed] but the user can pick their own in
/// Settings, which flows through every screen.
class AppTheme {
  AppTheme._();

  /// Default accent colour: a modern indigo-violet.
  static const Color defaultSeed = Color(0xFF5A4FCF);

  /// Themes for the default seed (used by tests and as a fallback).
  static ThemeData get light => lightFor(defaultSeed);
  static ThemeData get dark => darkFor(defaultSeed);

  /// Light theme generated from [seed].
  static ThemeData lightFor(Color seed) => _build(_lightScheme(seed));

  /// Dark theme generated from [seed].
  static ThemeData darkFor(Color seed) => _build(
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      );

  /// Light scheme: the seed drives the brand/accent colours, while the surface
  /// ramp and outlines are tuned for crisp, layered, modern light surfaces.
  static ColorScheme _lightScheme(Color seed) =>
      ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light)
          .copyWith(
        // Cool, near-white surfaces with a clear elevation ramp for depth.
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
