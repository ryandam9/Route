import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Material 3 light/dark themes for the app.
///
/// Both themes are generated from an accent ("seed") colour the user can pick
/// in Settings.
///
/// * For the [defaultSeed] the app keeps its bespoke, hand-tuned schemes so the
///   default look never changes.
/// * For any other (user-chosen) accent the colour scheme is generated with
///   [FlexColorScheme] (rydmike.com), which produces a cohesive seeded palette
///   with nicely blended surfaces.
///
/// A shared [compose] pass then layers a comprehensive set of Material 3
/// component themes — cards, inputs, buttons, chips, navigation, dialogs — on
/// top so the whole app shares one cohesive, modern visual identity.
class AppTheme {
  AppTheme._();

  /// Default accent: a vivid royal violet — energetic and premium.
  static const Color defaultSeed = Color(0xFF6D4AFF);

  /// Themes for the default seed (used by tests and as a fallback).
  static ThemeData get light => lightFor(defaultSeed);
  static ThemeData get dark => darkFor(defaultSeed);

  static bool _isDefault(Color seed) =>
      seed.toARGB32() == defaultSeed.toARGB32();

  /// Light theme generated from [seed].
  static ThemeData lightFor(Color seed) => compose(
        _isDefault(seed)
            ? _defaultLightScheme(seed)
            : FlexColorScheme.light(
                primary: seed,
                keyColors: const FlexKeyColors(keepPrimary: true),
                surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
                blendLevel: 4,
                appBarElevation: 0,
                useMaterial3: true,
              ).toScheme,
        Brightness.light,
      );

  /// Dark theme generated from [seed].
  static ThemeData darkFor(Color seed) => compose(
        _isDefault(seed)
            ? _defaultDarkScheme(seed)
            : FlexColorScheme.dark(
                primary: seed,
                primaryLightRef: seed,
                keyColors: const FlexKeyColors(keepPrimary: true),
                surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
                blendLevel: 8,
                appBarElevation: 0,
                useMaterial3: true,
              ).toScheme,
        Brightness.dark,
      );

  /// The shared component-theme pass. Layering every widget theme on top of a
  /// single [ColorScheme] keeps the look consistent for both the bespoke
  /// default palette and any user-chosen accent.
  static ThemeData compose(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 3,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );

    return _withAppBar(
      base.copyWith(
        textTheme: _typography(base.textTheme, isDark),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
          thickness: 1,
          space: 1,
        ),
        inputDecorationTheme: _inputDecoration(scheme),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 46),
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 46),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: BorderSide(color: scheme.outline, width: 1.4),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide(color: scheme.outlineVariant),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        dialogTheme: DialogThemeData(
          elevation: 0,
          backgroundColor: scheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titleTextStyle: TextStyle(
            color: scheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 15,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: scheme.inverseSurface,
          contentTextStyle: TextStyle(color: scheme.onInverseSurface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: scheme.surfaceContainer,
          surfaceTintColor: scheme.surfaceTint,
          elevation: 0,
          height: 72,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
            );
          }),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: scheme.surfaceContainerLow,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: scheme.inverseSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
          waitDuration: const Duration(milliseconds: 400),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: scheme.primary,
          linearTrackColor: scheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: scheme.primary,
          inactiveTrackColor: scheme.surfaceContainerHighest,
          thumbColor: scheme.primary,
          overlayColor: scheme.primary.withValues(alpha: 0.12),
          trackHeight: 4,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.onPrimary;
            return scheme.outline;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary;
            }
            return scheme.surfaceContainerHighest;
          }),
          trackOutlineColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.transparent;
            return scheme.outlineVariant;
          }),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: scheme.surfaceContainerHigh,
          surfaceTintColor: scheme.surfaceTint,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        tabBarTheme: TabBarThemeData(
          indicatorColor: scheme.primary,
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
        ),
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: scheme.primary.withValues(alpha: 0.28),
          cursorColor: scheme.primary,
          selectionHandleColor: scheme.primary,
        ),
      ),
      isDark,
    );
  }

  /// A larger, brand-tinted page header shared by every screen's [AppBar]:
  /// a frosted surface that gains a subtle shadow when content scrolls under
  /// it. (The previous heavy `primaryContainer` header felt heavy; this reads
  /// modern and lets the content breathe.)
  static ThemeData _withAppBar(ThemeData base, bool isDark) {
    final scheme = base.colorScheme;
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: isDark ? 2 : 3,
        shadowColor: scheme.shadow.withValues(alpha: 0.10),
        centerTitle: false,
        titleTextStyle: (base.textTheme.titleLarge ?? const TextStyle())
            .copyWith(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  /// Input fields: filled, rounded, with a crisp accent ring on focus.
  static InputDecorationTheme _inputDecoration(ColorScheme scheme) {
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      border: outline,
      enabledBorder: outline,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    );
  }

  /// Slightly bolder display/headline weights for a more confident hierarchy.
  static TextTheme _typography(TextTheme base, bool isDark) {
    TextStyle bump(TextStyle? s, {FontWeight weight = FontWeight.w700}) =>
        (s ?? const TextStyle()).copyWith(fontWeight: weight);
    return base.copyWith(
      displayLarge: bump(base.displayLarge),
      displayMedium: bump(base.displayMedium),
      displaySmall: bump(base.displaySmall),
      headlineLarge: bump(base.headlineLarge),
      headlineMedium: bump(base.headlineMedium),
      headlineSmall: bump(base.headlineSmall),
      titleLarge: bump(base.titleLarge),
      titleMedium:
          bump(base.titleMedium, weight: FontWeight.w600),
      titleSmall: bump(base.titleSmall, weight: FontWeight.w600),
      labelLarge:
          bump(base.labelLarge, weight: FontWeight.w600),
    );
  }

  /// The bespoke default light scheme: vivid brand colours over a cool, layered
  /// near-white surface ramp for crisp, modern depth.
  static ColorScheme _defaultLightScheme(Color seed) =>
      ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light)
          .copyWith(
        primary: const Color(0xFF6D4AFF),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFE8DEFF),
        onPrimaryContainer: const Color(0xFF1E0F4D),
        secondary: const Color(0xFF5B5BD6),
        secondaryContainer: const Color(0xFFE2E0FF),
        onSecondaryContainer: const Color(0xFF16164A),
        tertiary: const Color(0xFF00B8D4),
        tertiaryContainer: const Color(0xFFC4F2FB),
        onTertiaryContainer: const Color(0xFF00363F),
        surface: const Color(0xFFFBFAFF),
        onSurface: const Color(0xFF1A1A24),
        onSurfaceVariant: const Color(0xFF494955),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF5F3FC),
        surfaceContainer: const Color(0xFFEFEDF8),
        surfaceContainerHigh: const Color(0xFFE9E7F3),
        surfaceContainerHighest: const Color(0xFFE3E1EE),
        outline: const Color(0xFF75737F),
        outlineVariant: const Color(0xFFC8C5D4),
        shadow: const Color(0xFF1A1A24),
      );

  /// The bespoke default dark scheme: the same vivid brand over a true-dark,
  /// slightly violet-tinted surface ramp with strong contrast.
  static ColorScheme _defaultDarkScheme(Color seed) =>
      ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark)
          .copyWith(
        primary: const Color(0xFFC8B8FF),
        onPrimary: const Color(0xFF2E1380),
        primaryContainer: const Color(0xFF4A2FB0),
        onPrimaryContainer: const Color(0xFFE8DEFF),
        secondary: const Color(0xFFC4C2FF),
        onSecondary: const Color(0xFF2A2A6E),
        secondaryContainer: const Color(0xFF3A3A7A),
        onSecondaryContainer: const Color(0xFFE2E0FF),
        tertiary: const Color(0xFF5CE6FF),
        onTertiary: const Color(0xFF00363F),
        tertiaryContainer: const Color(0xFF004F5C),
        onTertiaryContainer: const Color(0xFFB8F2FF),
        surface: const Color(0xFF121219),
        onSurface: const Color(0xFFE5E4F0),
        onSurfaceVariant: const Color(0xFFB0AEC4),
        surfaceContainerLowest: const Color(0xFF0C0C12),
        surfaceContainerLow: const Color(0xFF1A1A24),
        surfaceContainer: const Color(0xFF1F1F2B),
        surfaceContainerHigh: const Color(0xFF262633),
        surfaceContainerHighest: const Color(0xFF2E2E3D),
        outline: const Color(0xFF8A889E),
        outlineVariant: const Color(0xFF44444F),
        shadow: Colors.black,
      );
}
