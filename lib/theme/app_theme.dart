import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Material 3 light/dark themes for the app.
///
/// Both themes are generated from an accent ("seed") colour the user can pick
/// in Settings.
///
/// * For the [defaultSeed] the app keeps its bespoke, hand-tuned theme so the
///   default look never changes.
/// * For any other (user-chosen) accent the themes are generated with
///   [FlexColorScheme] (rydmike.com), which produces a cohesive seeded palette
///   with nicely blended surfaces.
class AppTheme {
  AppTheme._();

  /// Default accent colour: a modern indigo-violet.
  static const Color defaultSeed = Color(0xFF5A4FCF);

  /// Themes for the default seed (used by tests and as a fallback).
  static ThemeData get light => lightFor(defaultSeed);
  static ThemeData get dark => darkFor(defaultSeed);

  static bool _isDefault(Color seed) =>
      seed.toARGB32() == defaultSeed.toARGB32();

  /// Light theme generated from [seed].
  static ThemeData lightFor(Color seed) => _withAppBar(_isDefault(seed)
      ? _build(_defaultLightScheme(seed))
      : FlexThemeData.light(
          primary: seed,
          keyColors: const FlexKeyColors(keepPrimary: true),
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 2,
          appBarElevation: 0,
          useMaterial3: true,
        ));

  /// Dark theme generated from [seed].
  static ThemeData darkFor(Color seed) => _withAppBar(_isDefault(seed)
      ? _build(ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark))
      : FlexThemeData.dark(
          primary: seed,
          // The dark theme is seeded from the same accent as the light theme;
          // tell FlexColorScheme so it can derive the M3 "fixed" colours
          // correctly (otherwise it warns that primaryLightRef is null).
          primaryLightRef: seed,
          keyColors: const FlexKeyColors(keepPrimary: true),
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 6,
          appBarElevation: 0,
          useMaterial3: true,
        ));

  /// A bigger, brand-tinted page header shared by every screen's [AppBar]:
  /// a larger, bold title on a [ColorScheme.primaryContainer] background so
  /// page headings stand out consistently across the app.
  static ThemeData _withAppBar(ThemeData base) {
    final scheme = base.colorScheme;
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: (base.textTheme.titleLarge ?? const TextStyle()).copyWith(
          color: scheme.onPrimaryContainer,
          fontSize: 23,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// The bespoke default light scheme: the seed drives the brand colours, while
  /// the surface ramp and outlines are tuned for crisp, layered, modern light
  /// surfaces. Only used for [defaultSeed].
  static ColorScheme _defaultLightScheme(Color seed) =>
      ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light)
          .copyWith(
        surface: const Color(0xFFFCFBFF),
        onSurface: const Color(0xFF1B1B23),
        onSurfaceVariant: const Color(0xFF45454F),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF6F4FC),
        surfaceContainer: const Color(0xFFF0EEF8),
        surfaceContainerHigh: const Color(0xFFEAE8F3),
        surfaceContainerHighest: const Color(0xFFE4E2EE),
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
