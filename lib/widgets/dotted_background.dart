import 'package:flutter/material.dart';

/// A calm aurora backdrop: two soft radial washes of the theme's accent hues
/// breathing at the top of the page, fading into the scaffold. It lifts plain
/// surfaces with gentle light and depth while staying almost subliminal.
/// Cheap — painted once per theme change, no per-frame work.
///
/// Replaces the old Neo Brutalist dot-grid. The legacy [spacing]/[radius]/
/// [color] parameters are kept for source compatibility but no longer used.
class DottedBackground extends StatelessWidget {
  const DottedBackground({
    super.key,
    required this.child,
    this.spacing = 22,
    this.radius = 1.3,
    this.color,
  });

  final Widget child;
  final double spacing;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _AuroraPainter(
        surface: scheme.surface,
        primary: scheme.primary,
        secondary: scheme.secondary,
        dark: scheme.brightness == Brightness.dark,
      ),
      child: child,
    );
  }
}

/// Paints the scaffold surface with two overlapping accent glows — the primary
/// hue drifting in from the top trailing corner, the secondary from the top
/// leading edge — like early-morning light on a wall.
class _AuroraPainter extends CustomPainter {
  const _AuroraPainter({
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.dark,
  });

  final Color surface;
  final Color primary;
  final Color secondary;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = surface);

    void glow(Offset center, double r, Color c, double alpha) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [c.withValues(alpha: alpha), c.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, paint);
    }

    final w = size.width;
    final h = size.height;
    // In dark theme the glows carry slightly more weight — they're the only
    // ambient light on the charcoal — but both stay whisper-quiet.
    glow(Offset(w * 0.86, -h * 0.06), w * 0.62, primary, dark ? 0.10 : 0.07);
    glow(Offset(w * 0.02, h * 0.10), w * 0.50, secondary, dark ? 0.07 : 0.05);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.surface != surface ||
      old.primary != primary ||
      old.secondary != secondary ||
      old.dark != dark;
}
