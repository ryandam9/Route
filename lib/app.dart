import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/app_font.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_tokens.dart';

/// Wombat's signature route transition: the incoming page fades in while
/// rising gently and settling from a whisper of scale, as if the surface is
/// being laid onto the desk; the outgoing page recedes a touch beneath it.
/// Calmer and more dimensional than a sideways slide, and direction-neutral,
/// so it reads correctly whether a route is a peer or a detail.
class GentleRisePageTransitionsBuilder extends PageTransitionsBuilder {
  const GentleRisePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Entering: a long, soft landing. Reversed (pop): a brisk exit.
    final enter = CurvedAnimation(
      parent: animation,
      curve: AppTokens.curveEmphasized,
      reverseCurve: AppTokens.curveExit.flipped,
    );
    // The fade completes early so the rise/settle plays out on a fully
    // opaque page instead of a ghost.
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      reverseCurve: const Interval(0.55, 1.0, curve: Curves.easeIn),
    );
    // Beneath a covering route the page steps back slightly and dims,
    // giving the stack real depth without parallax gimmicks.
    final recede = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInOutCubic,
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(enter),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(enter),
          filterQuality: FilterQuality.medium,
          child: AnimatedBuilder(
            animation: recede,
            child: child,
            builder: (context, child) => Transform.scale(
              scale: 1 - 0.035 * recede.value,
              filterQuality:
                  recede.isDismissed ? null : FilterQuality.medium,
              child: Opacity(
                opacity: 1 - 0.20 * recede.value,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The gentle-rise transition on every platform.
const _pageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: GentleRisePageTransitionsBuilder(),
    TargetPlatform.iOS: GentleRisePageTransitionsBuilder(),
    TargetPlatform.linux: GentleRisePageTransitionsBuilder(),
    TargetPlatform.macOS: GentleRisePageTransitionsBuilder(),
    TargetPlatform.windows: GentleRisePageTransitionsBuilder(),
  },
);

/// No-op page transition (routes appear instantly) for reduced motion.
class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(route, context, animation, secondaryAnimation,
          Widget child) =>
      child;
}

const _noPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _NoTransitionsBuilder(),
    TargetPlatform.iOS: _NoTransitionsBuilder(),
    TargetPlatform.linux: _NoTransitionsBuilder(),
    TargetPlatform.macOS: _NoTransitionsBuilder(),
    TargetPlatform.windows: _NoTransitionsBuilder(),
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
    final bg = ref.watch(settingsProvider.select((s) => s.bgColor));
    final reduce = ref.watch(settingsProvider.select((s) => s.reduceMotion));
    return MaterialApp(
      title: 'Wombat',
      debugShowCheckedModeBanner: false,
      theme: _withHeadingFont(
          AppTheme.lightFor(seed, background: bg), headingFont, reduce),
      darkTheme: _withHeadingFont(
          AppTheme.darkFor(seed, background: bg), headingFont, reduce),
      themeMode: themeMode,
      // A gentle crossfade when the theme, accent or background tint changes
      // (light⇄dark, picking an accent) rather than an instant snap. Honours
      // reduced motion.
      themeAnimationDuration:
          reduce ? Duration.zero : const Duration(milliseconds: 350),
      themeAnimationCurve: Curves.easeInOut,
      // Fold the "Reduce motion" setting into MediaQuery.disableAnimations so
      // it propagates everywhere (Motion helper, shimmer, implicit anims).
      //
      // Text selection is scoped to the chat transcript (see ChatView) rather
      // than a single app-wide SelectionArea: wrapping the whole, constantly
      // rebuilding/animating UI tripped a framework ConcurrentModificationError
      // in SelectableRegion as the set of selectables churned.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
              disableAnimations: mq.disableAnimations || reduce),
          child: child ?? const SizedBox(),
        );
      },
      home: const HomeScreen(),
    );
  }

  /// Applies the chosen [font] to the display/headline/title text styles so
  /// headings use it while body text keeps its per-widget font.
  ThemeData _withHeadingFont(ThemeData base, AppFont font, bool reduce) {
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
      pageTransitionsTheme: reduce ? _noPageTransitions : _pageTransitions,
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: (base.appBarTheme.titleTextStyle ?? t.titleLarge)
            ?.copyWith(fontFamily: fam),
      ),
    );
  }
}
