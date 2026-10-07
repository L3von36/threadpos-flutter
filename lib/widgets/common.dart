import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Product photo with a graceful offline fallback.
Widget productImage(String url, {BoxFit fit = BoxFit.cover}) {
  if (url.isEmpty) {
    return _imagePlaceholder();
  }
  return Image.network(
    url,
    fit: fit,
    errorBuilder:
        (BuildContext context, Object error, StackTrace? stackTrace) =>
            _imagePlaceholder(),
    loadingBuilder:
        (BuildContext context, Widget child, ImageChunkEvent? progress) {
      if (progress == null) return child;
      return const ColoredBox(
        color: AppTheme.creamDeep,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 1.8, color: AppTheme.terracotta),
          ),
        ),
      );
    },
  );
}

Widget _imagePlaceholder() {
  return const ColoredBox(
    color: AppTheme.creamDeep,
    child: Center(
      child: Icon(Icons.checkroom, color: AppTheme.muted, size: 24),
    ),
  );
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppTheme.terracotta,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(height: 7),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10.5, height: 1.15, color: AppTheme.muted)),
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
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(title, style: AppTheme.sectionTitle),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.terracotta)),
            ),
        ],
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color = AppTheme.terracotta,
    this.track = AppTheme.creamDeep,
  });

  final double value; // 0..1
  final double height;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    double v = value;
    if (v.isNaN || v < 0) v = 0;
    if (v > 1) v = 1;
    return Container(
      height: height,
      decoration: BoxDecoration(
          color: track, borderRadius: BorderRadius.circular(height)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v,
            child: Container(color: color),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                  color: AppTheme.creamDeep, shape: BoxShape.circle),
              child: Icon(icon, size: 24, color: AppTheme.muted),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      backgroundColor: AppTheme.ink,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.rSm)),
    ),
  );
}
