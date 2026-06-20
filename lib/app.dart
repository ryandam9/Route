import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/app_font.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

/// Smooth Material-motion page transitions on every platform (pushed routes
/// fade through + slide along the shared axis).
const _pageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: SharedAxisPageTransitionsBuilder(
      transitionType: SharedAxisTransitionType.horizontal,
    ),
    TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
      transitionType: SharedAxisTransitionType.horizontal,
    ),
    TargetPlatform.linux: SharedAxisPageTransitionsBuilder(
      transitionType: SharedAxisTransitionType.horizontal,
    ),
    TargetPlatform.macOS: SharedAxisPageTransitionsBuilder(
      transitionType: SharedAxisTransitionType.horizontal,
    ),
    TargetPlatform.windows: SharedAxisPageTransitionsBuilder(
      transitionType: SharedAxisTransitionType.horizontal,
    ),
  },
);

class WombatApp extends ConsumerWidget {
  const WombatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final headingFont =
        ref.watch(settingsProvider.select((s) => s.headingFont));
    final seed = ref.watch(settingsProvider.select((s) => s.seedColor));
    return MaterialApp(
      title: 'Wombat',
      debugShowCheckedModeBanner: false,
      theme: _withHeadingFont(AppTheme.lightFor(seed), headingFont),
      darkTheme: _withHeadingFont(AppTheme.darkFor(seed), headingFont),
      themeMode: themeMode,
      // Make text selectable anywhere in the app. SelectionArea needs an
      // Overlay ancestor for its selection handles/toolbar; the app's own
      // Navigator overlay is a descendant here, so we provide one above it.
      // TextFields keep their own editing selection.
      builder: (context, child) => Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) =>
                SelectionArea(child: child ?? const SizedBox()),
          ),
        ],
      ),
      home: const HomeScreen(),
    );
  }

  /// Applies the chosen [font] to the display/headline/title text styles so
  /// headings use it while body text keeps its per-widget font.
  ThemeData _withHeadingFont(ThemeData base, AppFont font) {
    final fam = font.family;
    final t = base.textTheme;
    final headed = t.copyWith(
      displayLarge: t.displayLarge?.copyWith(fontFamily: fam),
      displayMedium: t.displayMedium?.copyWith(fontFamily: fam),
      displaySmall: t.displaySmall?.copyWith(fontFamily: fam),
      headlineLarge: t.headlineLarge?.copyWith(fontFamily: fam),
      headlineMedium: t.headlineMedium?.copyWith(fontFamily: fam),
      headlineSmall: t.headlineSmall?.copyWith(fontFamily: fam),
      titleLarge: t.titleLarge?.copyWith(fontFamily: fam),
      titleMedium: t.titleMedium?.copyWith(fontFamily: fam),
      titleSmall: t.titleSmall?.copyWith(fontFamily: fam),
    );
    return base.copyWith(
      textTheme: headed,
      pageTransitionsTheme: _pageTransitions,
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: (base.appBarTheme.titleTextStyle ?? t.titleLarge)
            ?.copyWith(fontFamily: fam),
      ),
    );
  }
}
