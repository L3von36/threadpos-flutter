import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'motion.dart';

/// Product photo with a graceful offline fallback.
Widget productImage(BuildContext context, String url, {BoxFit fit = BoxFit.cover}) {
  if (url.isEmpty) {
    return _imagePlaceholder(context);
  }
  return Image.network(
    url,
    fit: fit,
    errorBuilder:
        (BuildContext context, Object error, StackTrace? stackTrace) =>
            _imagePlaceholder(context),
    loadingBuilder:
        (BuildContext context, Widget child, ImageChunkEvent? progress) {
      if (progress == null) return child;
      return ColoredBox(
        color: Pal.of(context).surfaceAlt,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 1.8, color: Pal.of(context).accent),
          ),
        ),
      );
    },
  );
}

Widget _imagePlaceholder(BuildContext context) {
  final Pal pal = Pal.of(context);
  return ColoredBox(
    color: pal.surfaceAlt,
    child: Center(
      child: Icon(Icons.checkroom, color: pal.muted, size: 24),
    ),
  );
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        border: Border.all(color: pal.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 15, color: color ?? pal.accent),
          const SizedBox(height: 7),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: pal.ink)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10.5, height: 1.15, color: pal.muted)),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(title, style: AppTheme.sectionTitle(context)),
          ),
          if (actionLabel != null)
            PressableScale(
              onTap: onAction,
              pressedScale: 0.94,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Text(actionLabel!,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: pal.accent)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thin progress bar whose fill animates to its value on mount and on
/// every change — used for shift targets, mix rows and leaderboards.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
    this.track,
  });

  final double value; // 0..1
  final double height;
  final Color? color;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    double v = value;
    if (v.isNaN || v < 0) v = 0;
    if (v > 1) v = 1;
    return Container(
      height: height,
      decoration: BoxDecoration(
          color: track ?? pal.surfaceAlt,
          borderRadius: BorderRadius.circular(height)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: v),
            duration: Motion.slow,
            curve: Motion.out,
            builder: (BuildContext context, double t, _) =>
                FractionallySizedBox(
              widthFactor: t,
              child: Container(color: color ?? pal.accent),
            ),
          ),
        ),
      ),
    );
  }
}

class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9.5,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PopIn(
              begin: 0.6,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: pal.surfaceAlt, shape: BoxShape.circle),
                child: Icon(icon, size: 24, color: pal.muted),
              ),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: pal.ink)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: pal.muted)),
          ],
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String message) {
  final Pal pal = Pal.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      backgroundColor: pal.toastBg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.rSm)),
    ),
  );
}
