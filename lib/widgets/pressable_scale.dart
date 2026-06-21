import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps [child] so it scales down slightly while pressed, giving tactile
/// feedback on taps. Uses a [Listener] so it never steals the child's own tap
/// handling (buttons, InkWells, etc. keep working).
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.scale = 0.96,
    this.haptic = true,
  });

  final Widget child;
  final double scale;

  /// Whether to emit a light selection tick on press-down for tactile feedback.
  /// Disable for controls that already trigger their own haptics.
  final bool haptic;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) {
      if (v && widget.haptic) HapticFeedback.selectionClick();
      setState(() => _pressed = v);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
