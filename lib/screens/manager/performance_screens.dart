import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

/// Performance management — real per-seller numbers from the sale log
/// across Today / 7 / 30 days, with an editable daily target and the
/// commission rate that drives every payout estimate.
class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  SalesRange _range = SalesRange.today;

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final Map<String, double> bySeller =
        store.revenueBySellerFor(_range);
    final double totalRevenue = bySeller.values.fold(0.0, (double s, double v) => s + v);

    // Join sellers to roster entries (for avatar + branch).
    final List<_SellerRow> rows = <_SellerRow>[];
    for (final MapEntry<String, double> entry in bySeller.entries) {
      Employee? match;
      for (final Employee e in store.employees) {
        if (e.firstName == entry.key) {
          match = e;
          break;
        }
      }
      final List<Sale> sellerSales =
          store.salesForSeller(entry.key, _range);
      rows.add(_SellerRow(
        name: match?.name ??
            (entry.key.isEmpty
                ? 'Unknown'
                : entry.key[0].toUpperCase() + entry.key.substring(1)),
        branch: match?.branch ?? 'Unassigned',
        revenue: entry.value,
        orders: sellerSales.length,
        units: store.itemsFor(sellerSales),
        conversion: match?.conversion ?? 0,
      ));
    }
    rows.sort((_SellerRow a, _SellerRow b) => b.revenue.compareTo(a.revenue));
    final double maxRevenue =
        rows.isEmpty ? 1 : rows.first.revenue;

    return Scaffold(
      appBar: AppBar(title: const Text('Performance')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Ranking',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: pal.ink)),
              _RangeTabs(
                value: _range,
                onChanged: (SalesRange r) => setState(() => _range = r),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Target + commission settings card.
          StaggerIn(
            index: 0,
            dy: 8,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pal.surfaceAlt.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.rMd),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.flag_outlined, size: 16, color: pal.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Daily team target',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: pal.ink)),
                      ),
                      PressableScale(
                        onTap: () => _editTarget(context, store.dailyTarget),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: pal.softAccent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(money(store.dailyTarget),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: pal.accent)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ProgressBar(
                      value: totalRevenue <= 0
                          ? 0
                          : totalRevenue / store.dailyTarget,
                      height: 6),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                          '${(totalRevenue / (store.dailyTarget <= 0 ? 1 : store.dailyTarget) * 100).round()}% of target reached',
                          style: TextStyle(
                              fontSize: 11, color: pal.muted)),
                      Text('Commission ${store.commissionRate.toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: pal.sage)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Text('No sales recorded in this period.',
                style: TextStyle(fontSize: 12, color: pal.muted))
          else
            ...rows
                .asMap()
                .entries
                .map((MapEntry<int, _SellerRow> entry) {
              final int i = entry.key;
              final _SellerRow r = entry.value;
              final double share =
                  totalRevenue <= 0 ? 0 : r.revenue / totalRevenue;
              return StaggerIn(
                index: i + 1,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: pal.surface,
                    borderRadius: BorderRadius.circular(AppTheme.rMd),
                    border: Border.all(color: pal.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      PopIn(
                        begin: 0.6,
                        duration: Motion.base,
                        child: Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == 0
                                ? pal.amber
                                : (i == 1 ? pal.accent : pal.surfaceAlt),
                            shape: BoxShape.circle,
                          ),
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: i <= 1
                                      ? Colors.white
                                      : pal.ink)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Expanded(
                                  child: Text(r.name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          color: pal.ink)),
                                ),
                                Text(money(r.revenue),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: pal.accent)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                                '${r.branch} · ${r.orders} orders · ${r.units} units · ${(share * 100).toStringAsFixed(0)}% of sales',
                                style: TextStyle(
                                    fontSize: 10.5, color: pal.muted)),
                            const SizedBox(height: 5),
                            ProgressBar(
                                value: maxRevenue <= 0
                                    ? 0
                                    : r.revenue / maxRevenue,
                                height: 5),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                    'Avg. order ${money(r.orders == 0 ? 0 : r.revenue / r.orders)}',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: pal.muted)),
                                Text(
                                    'Commission ${money(r.revenue * store.commissionRate / 100)}',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: pal.sage)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 6),
          StaggerIn(
            index: 20,
            dy: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: pal.sage.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.rMd),
                border: Border.all(
                    color: pal.sage.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.emoji_events_outlined,
                      size: 16, color: pal.sage),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        rows.isEmpty
                            ? 'Waiting for the first sale of the period.'
                            : 'Top performer: ${rows.first.name} — share the win with the team.',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: pal.ink)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editTarget(BuildContext context, double current) {
    final TextEditingController controller =
        TextEditingController(text: current.round().toString());
    final Pal pal = Pal.of(context);
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.rLg)),
        title: const Text('Set daily target',
            style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: AppTheme.input(context, 'Target (ETB)',
              icon: Icons.flag_outlined),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final double? v = double.tryParse(controller.text.trim());
              if (v != null && v > 0) {
                context.read<Store>().setDailyTarget(v);
              }
              Navigator.of(dialogContext).pop();
              showSnack(context, 'Daily target updated');
            },
            style:
                FilledButton.styleFrom(backgroundColor: pal.accent),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SellerRow {
  const _SellerRow({
    required this.name,
    required this.branch,
    required this.revenue,
    required this.orders,
    required this.units,
    required this.conversion,
  });

  final String name;
  final String branch;
  final double revenue;
  final int orders;
  final int units;
  final int conversion;
}

/// Same pill-style range switcher as the manager analytics view.
class _RangeTabs extends StatelessWidget {
  const _RangeTabs({required this.value, required this.onChanged});

  final SalesRange value;
  final ValueChanged<SalesRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: pal.surfaceAlt.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: SalesRange.values
            .map((SalesRange r) => PressableScale(
                  onTap: () => onChanged(r),
                  pressedScale: 0.94,
                  child: AnimatedContainer(
                    duration: Motion.base,
                    curve: Motion.out,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: value == r ? pal.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(r.label,
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: value == r
                                ? Colors.white
                                : pal.muted)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
