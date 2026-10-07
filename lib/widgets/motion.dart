import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Central motion language for ThreadPOS.
///
/// Every animation in the app draws its durations and curves from here so
/// the whole product moves with one personality: quick presses (120ms),
/// smooth transitions (220-280ms) and confident reveals (350-550ms),
/// all settling with ease-out curves.
class Motion {
  Motion._();

  static const Duration press = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 360);
  static const Duration reveal = Duration(milliseconds: 550);

  /// Delay added per stagger index (capped downstream).
  static const Duration staggerStep = Duration(milliseconds: 35);

  /// Standard settle curve.
  static const Curve out = Curves.easeOutCubic;

  /// Springy pop curve for icons, checks and badges.
  static const Curve pop = Curves.easeOutBack;
}

/// Press & hover feedback wrapper.
///
/// Scales down while pressed (even around buttons, via pointer listener),
/// lifts slightly under a mouse cursor on desktop, and optionally handles
/// taps for non-button children. Give it an [onTap] only when the child
/// has no button of its own — otherwise let the child's own handler win.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
    this.hoverScale = 1.02,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final double hoverScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final double target = _pressed
        ? widget.pressedScale
        : (_hovered ? widget.hoverScale : 1.0);
    return MouseRegion(
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: GestureDetector(
          // Opaque so gaps between children still register taps when this
          // widget owns the gesture; harmless passthrough when onTap is
          // null (no recognizer is registered, child buttons keep taps).
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: target,
            duration: Motion.press,
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// One-shot entrance: fades in and slides up, staggered by [index].
///
/// Use [index] for list/grid order (delay caps after a few items) or pass
/// an explicit [delay] for choreographed reveals.
class StaggerIn extends StatefulWidget {
  const StaggerIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delay,
    this.dy = 12,
    this.duration = Motion.base,
  });

  final Widget child;
  final int index;
  final Duration? delay;
  final double dy;
  final Duration duration;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn> {
  bool _go = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final int i = widget.index;
    final int step = i < 0 ? 0 : (i > 6 ? 6 : i);
    _timer = Timer(widget.delay ?? Motion.staggerStep * step, () {
      if (mounted) setState(() => _go = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: _go ? 1 : 0),
      duration: widget.duration,
      curve: Motion.out,
      builder: (BuildContext context, double t, Widget? child) {
        return Opacity(
          opacity: t < 0 ? 0 : (t > 1 ? 1 : t),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.dy),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Scale-bumps its child whenever [trigger] changes.
///
/// Used for cart badges, quantity counters and live numbers so data
/// changes feel acknowledged rather than silent.
class BumpOnChange extends StatefulWidget {
  const BumpOnChange({
    super.key,
    required this.trigger,
    required this.child,
    this.amount = 0.22,
    this.duration = const Duration(milliseconds: 300),
  });

  final Object trigger;
  final Widget child;
  final double amount;
  final Duration duration;

  @override
  State<BumpOnChange> createState() => _BumpOnChangeState();
}

class _BumpOnChangeState extends State<BumpOnChange> {
  int _gen = 0;

  @override
  void didUpdateWidget(BumpOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      setState(() => _gen++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(_gen),
      tween: Tween<double>(begin: 0, end: 1),
      duration: widget.duration,
      curve: Curves.linear,
      builder: (BuildContext context, double t, Widget? child) {
        final double scale = 1 + widget.amount * math.sin(t * math.pi);
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}

/// Animated numeric text — counts from the previous value to [value]
/// using [formatter] (e.g. `money`), ideal for revenue and totals.
class CountUpText extends StatelessWidget {
  const CountUpText(
    this.value, {
    super.key,
    required this.style,
    required this.formatter,
    this.duration = Motion.reveal,
    this.begin = 0,
  });

  final double value;
  final TextStyle style;
  final String Function(double) formatter;
  final Duration duration;
  final double begin;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: value),
      duration: duration,
      curve: Motion.out,
      builder: (BuildContext context, double v, _) =>
          Text(formatter(v), style: style),
    );
  }
}

/// One-shot springy scale-in for hero moments (success check, avatars).
class PopIn extends StatelessWidget {
  const PopIn({
    super.key,
    required this.child,
    this.begin = 0.5,
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget child;
  final double begin;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: 1),
      duration: duration,
      curve: Motion.pop,
      builder: (BuildContext context, double t, Widget? child) =>
          Transform.scale(scale: t, child: child),
      child: child,
    );
  }
}

/// Animated sun/moon switch for toggling between the light and dark
/// themes. The two icons cross-fade with a quarter-turn settle.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, required this.dark, required this.onToggle});

  final bool dark;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return PressableScale(
      onTap: onToggle,
      pressedScale: 0.88,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AnimatedSwitcher(
          duration: Motion.base,
          switchInCurve: Motion.pop,
          switchOutCurve: Motion.out,
          transitionBuilder: (Widget child, Animation<double> anim) {
            return FadeTransition(
              opacity: anim,
              child: RotationTransition(
                turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
                child: ScaleTransition(scale: anim, child: child),
              ),
            );
          },
          child: Icon(
            dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            key: ValueKey<bool>(dark),
            size: 20,
            color: pal.muted,
          ),
        ),
      ),
    );
  }
}
