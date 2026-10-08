import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
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

/// The reference-style "Added to sale" pill with a springy check icon.
void showAddedToast(BuildContext context, String productName) {
  final Pal pal = Pal.of(context);
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: <Widget>[
          PopIn(
            begin: 0.4,
            duration: const Duration(milliseconds: 300),
            child: Icon(Icons.check_circle_rounded,
                size: 17, color: pal.sage),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Added to sale · $productName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: pal.toastText)),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1600),
      backgroundColor: pal.toastBg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.rSm)),
    ),
  );
}

/// Deterministic EAN-style barcode graphic rendered from [value].
/// Pure CustomPainter — no packages, dark-mode aware via [color].
class BarcodeView extends StatelessWidget {
  const BarcodeView({
    super.key,
    required this.value,
    this.height = 44,
    this.showText = true,
    this.color,
  });

  final String value;
  final double height;
  final bool showText;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    final Color ink = color ?? pal.ink;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _BarcodePainter(value: value, color: ink),
          ),
        ),
        if (showText) ...<Widget>[
          const SizedBox(height: 3),
          Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              fontSize: 10,
              height: 1,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w600,
              color: pal.muted,
            ),
          ),
        ],
      ],
    );
  }
}

class _BarcodePainter extends CustomPainter {
  const _BarcodePainter({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    // Bar widths derived from character codes so every string produces a
    // stable, barcode-looking rhythm of thin/thick bars.
    const List<double> widths = <double>[1, 1.8, 2.6, 3.6];
    double x = 0;
    final int n = value.isEmpty ? 24 : value.length * 3 + 6;
    for (int i = 0; i < n && x < size.width; i++) {
      final int code =
          value.isEmpty ? 7 : value.codeUnitAt(i % value.length);
      final double w = widths[(code + i) % widths.length];
      if (i.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(x, 0, w, size.height),
          paint,
        );
      }
      x += w + 1.1;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) =>
      old.value != value || old.color != color;
}

/// Receipt viewer shared by the sales feeds ("Receipt" links) and the
/// success flow — a compact bottom sheet with the sale breakdown.
Future<void> showReceiptSheet(BuildContext context, Sale sale) {
  final Pal pal = Pal.of(context);
  return showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('Receipt #${sale.id}',
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: pal.ink)),
                const Spacer(),
                PressableScale(
                  onTap: () => Navigator.of(sheetContext).pop(),
                  pressedScale: 0.85,
                  child: Icon(Icons.close, size: 18, color: pal.muted),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${clockLabel(sale.time)} · ${sale.seller} · ${paymentMethodLabel(sale.method)}',
              style: TextStyle(fontSize: 11.5, color: pal.muted),
            ),
            const SizedBox(height: 10),
            ...sale.lines.map(
              (SaleLine l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                          '${l.name}${l.size.isEmpty ? '' : ' · ${l.size}'} × ${l.qty}',
                          style: TextStyle(
                              fontSize: 12.5, color: pal.ink)),
                    ),
                    Text(money(l.lineTotal),
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: pal.ink)),
                  ],
                ),
              ),
            ),
            if (sale.discount > 0) ...<Widget>[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Discount',
                      style:
                          TextStyle(fontSize: 12, color: pal.muted)),
                  Text('-${money(sale.discount)}',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: pal.sage)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Container(height: 0.8, color: pal.border),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Total',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: pal.ink)),
                Text(money(sale.total),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: pal.accent)),
              ],
            ),
            const SizedBox(height: 12),
            BarcodeView(value: sale.id, height: 34),
          ],
        ),
      ),
    ),
  );
}
