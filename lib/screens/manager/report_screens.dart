import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

// ---------------------------------------------------------------------------
// Shared report rendering
// ---------------------------------------------------------------------------

class _ReportHeaderCard extends StatelessWidget {
  const _ReportHeaderCard({required this.report, required this.subtitle});

  final ShiftReport report;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: pal.bannerBg,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('${report.type}-REPORT · ${report.register.toUpperCase()}',
              style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                  color: pal.bannerSub)),
          const SizedBox(height: 5),
          CountUpText(
            report.netSales,
            style: TextStyle(
                fontSize: 22,
                height: 1.05,
                fontWeight: FontWeight.w700,
                color: pal.bannerText),
            formatter: money,
          ),
          const SizedBox(height: 5),
          Text(subtitle,
              style: TextStyle(fontSize: 11.5, color: pal.bannerSub)),
        ],
      ),
    );
  }
}

Widget _reportRow(BuildContext context, String label, String value,
    {Color? valueColor, bool bold = false}) {
  final Pal pal = Pal.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(label,
              style:
                  TextStyle(fontSize: 12.5, color: pal.muted)),
        ),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w600,
                color: valueColor ?? pal.ink)),
      ],
    ),
  );
}

Widget _reportCard(BuildContext context, {required List<Widget> children}) {
  final Pal pal = Pal.of(context);
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: pal.surface,
      borderRadius: BorderRadius.circular(AppTheme.rLg),
      border: Border.all(color: pal.border),
    ),
    child: Column(children: children),
  );
}

// ---------------------------------------------------------------------------
// X report — mid-shift snapshot, drawer stays open
// ---------------------------------------------------------------------------

class XReportScreen extends StatelessWidget {
  const XReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final ShiftReport report = store.buildReport(type: 'X');

    return Scaffold(
      appBar: AppBar(title: const Text('X report')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          StaggerIn(
            index: 0,
            dy: 8,
            child: _ReportHeaderCard(
              report: report,
              subtitle:
                  'Snapshot ${clockLabel(report.time)} · ${report.cashier} · report ${report.id}',
            ),
          ),
          const SizedBox(height: 10),
          StaggerIn(
            index: 1,
            dy: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: pal.amber.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(AppTheme.rMd),
                border:
                    Border.all(color: pal.amber.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.info_outline, size: 16, color: pal.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Read-only mid-shift reading — the drawer stays open and totals keep counting.',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: pal.ink)),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Sales'),
          StaggerIn(
            index: 2,
            dy: 8,
            child: _reportCard(context, children: <Widget>[
              _reportRow(context, 'Transactions',
                  '${report.transactions}'),
              _reportRow(context, 'Items sold', '${report.itemsSold}'),
              _reportRow(context, 'Gross sales',
                  money(report.grossSales)),
              _reportRow(context, 'Discounts',
                  '-${money(report.discounts)}',
                  valueColor: pal.sage),
              Container(height: 0.8, color: pal.border, margin: const EdgeInsets.symmetric(vertical: 4)),
              _reportRow(context, 'Net sales',
                  money(report.netSales),
                  bold: true, valueColor: pal.accent),
              _reportRow(context, 'Avg. order',
                  money(report.avgOrder)),
            ]),
          ),
          const SectionHeader(title: 'Payments'),
          StaggerIn(
            index: 3,
            dy: 8,
            child: _reportCard(context, children: <Widget>[
              _reportRow(context, 'Cash', money(report.cash)),
              _reportRow(context, 'Card', money(report.card)),
              _reportRow(context, 'Mobile', money(report.mobile)),
              Container(height: 0.8, color: pal.border, margin: const EdgeInsets.symmetric(vertical: 4)),
              _reportRow(context, 'Opening float',
                  money(report.openingFloat)),
              _reportRow(context, 'Cash in drawer',
                  money(report.expectedDrawer),
                  bold: true),
            ]),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            index: 4,
            dy: 8,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: PressableScale(
                    child: OutlinedButton.icon(
                      onPressed: () => showSnack(
                          context, 'X report sent to the printer'),
                      icon: const Icon(Icons.print_outlined, size: 17),
                      label: const Text('Print'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PressableScale(
                    child: FilledButton.icon(
                      style: AppTheme.primaryButton(context),
                      onPressed: () => showSnack(
                          context, 'Report shared as text'),
                      icon: const Icon(Icons.ios_share, size: 16),
                      label: const Text('Share'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Z report — close of day with counted cash + variance, plus archive
// ---------------------------------------------------------------------------

class ZReportScreen extends StatefulWidget {
  const ZReportScreen({super.key});

  @override
  State<ZReportScreen> createState() => _ZReportScreenState();
}

class _ZReportScreenState extends State<ZReportScreen> {
  final TextEditingController _counted = TextEditingController();
  final TextEditingController _note = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _counted.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final ShiftReport report = store.buildReport(type: 'Z');
    if (!_prefilled) {
      _counted.text = report.expectedDrawer.round().toString();
      _prefilled = true;
    }
    final double counted =
        double.tryParse(_counted.text.trim()) ?? report.expectedDrawer;
    final double variance = counted - report.expectedDrawer;
    final bool closed = store.dayClosedToday;
    final List<ShiftReport> history = store.zReports;

    return Scaffold(
      appBar: AppBar(title: const Text('Z report')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
        children: <Widget>[
          if (closed) ...<Widget>[
            StaggerIn(
              index: 0,
              dy: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: pal.sage.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppTheme.rMd),
                  border: Border.all(
                      color: pal.sage.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: <Widget>[
                    PopIn(
                      begin: 0.5,
                      duration: Motion.base,
                      child: Icon(Icons.check_circle_rounded,
                          size: 17, color: pal.sage),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          'Register closed for today — see the archive below.',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: pal.ink)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          StaggerIn(
            index: 1,
            dy: 8,
            child: _ReportHeaderCard(
              report: report,
              subtitle:
                  'Live totals · ${report.transactions} transactions · ${report.cashier}',
            ),
          ),
          const SectionHeader(title: 'Close of day'),
          StaggerIn(
            index: 2,
            dy: 8,
            child: _reportCard(context, children: <Widget>[
              _reportRow(context, 'Net sales',
                  money(report.netSales), bold: true),
              _reportRow(context, 'Cash sales', money(report.cash)),
              _reportRow(context, 'Opening float',
                  money(report.openingFloat)),
              Container(height: 0.8, color: pal.border, margin: const EdgeInsets.symmetric(vertical: 4)),
              _reportRow(context, 'Expected drawer',
                  money(report.expectedDrawer), bold: true),
            ]),
          ),
          const SizedBox(height: 10),
          StaggerIn(
            index: 3,
            dy: 8,
            child: _reportCard(context, children: <Widget>[
              Text('Counted cash',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: pal.ink)),
              const SizedBox(height: 8),
              TextField(
                controller: _counted,
                keyboardType: const TextInputType.numberWithOptions(),
                onChanged: (String v) => setState(() {}),
                decoration: AppTheme.input(context,
                    'Physically counted drawer (ETB)',
                    icon: Icons.account_balance_wallet_outlined),
              ),
              const SizedBox(height: 10),
              _reportRow(context, 'Variance',
                  variance == 0
                      ? 'Balanced'
                      : '${variance > 0 ? '+' : '-'}${money(variance.abs())}',
                  bold: true,
                  valueColor: variance == 0
                      ? pal.sage
                      : (variance > 0 ? pal.amber : pal.danger)),
              Text(
                  variance == 0
                      ? 'Drawer matches the expected amount.'
                      : variance > 0
                          ? 'Over — extra cash in the drawer.'
                          : 'Short — missing cash or an unrecorded refund.',
                  style: TextStyle(fontSize: 10.5, color: pal.muted)),
              const SizedBox(height: 10),
              TextField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                decoration: AppTheme.input(context,
                    'Close-out note (optional)',
                    icon: Icons.notes,
                    hint: 'e.g. Short 20 — refund rounding'),
              ),
              const SizedBox(height: 12),
              PressableScale(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor:
                        closed ? pal.muted : pal.ink,
                    foregroundColor: pal.toastText,
                  ),
                  onPressed:
                      closed ? null : () => _confirmClose(context, counted),
                  child: Text(closed
                      ? 'Register closed'
                      : 'Close register (Z)'),
                ),
              ),
            ]),
          ),
          const SectionHeader(title: 'Z-report archive'),
          if (history.isEmpty)
            Text('No Z reports yet — close the register to create one.',
                style: TextStyle(fontSize: 12, color: pal.muted))
          else
            ...history
                .asMap()
                .entries
                .map((MapEntry<int, ShiftReport> entry) {
              final ShiftReport r = entry.value;
              final bool balanced = r.variance == 0;
              return StaggerIn(
                index: 4 + entry.key,
                dy: 6,
                child: PressableScale(
                  onTap: () => _showArchived(context, r),
                  pressedScale: 0.97,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: pal.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.rMd),
                      border: Border.all(color: pal.border),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: pal.surfaceAlt,
                            borderRadius:
                                BorderRadius.circular(9),
                          ),
                          child: Icon(Icons.lock_outline,
                              size: 16,
                              color: balanced
                                  ? pal.sage
                                  : pal.amber),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                  '${r.id} · ${shortDate(r.time)}',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: pal.ink)),
                              Text(
                                  '${r.transactions} sales · net ${money(r.netSales)} · ${r.cashier}',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: pal.muted)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                                balanced
                                    ? 'Balanced'
                                    : '${r.variance > 0 ? '+' : '-'}${money(r.variance.abs())}',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: balanced
                                        ? pal.sage
                                        : (r.variance > 0
                                            ? pal.amber
                                            : pal.danger))),
                            Text(clockLabel(r.time),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: pal.muted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _confirmClose(BuildContext context, double counted) {
    final Pal pal = Pal.of(context);
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.rLg)),
        title: const Text('Close the register?',
            style: TextStyle(fontSize: 16)),
        content: Text(
            'A Z report will lock ${money(counted)} counted cash with today\'s totals. This cannot be undone.',
            style: TextStyle(fontSize: 12.5, color: pal.muted)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: pal.ink,
                foregroundColor: pal.toastText),
            onPressed: () {
              context.read<Store>().closeDay(
                  countedCash: counted, note: _note.text.trim());
              Navigator.of(dialogContext).pop();
              showSnack(
                  context, 'Register closed — Z report archived');
            },
            child: const Text('Close day'),
          ),
        ],
      ),
    );
  }

  void _showArchived(BuildContext context, ShiftReport r) {
    showModalBottomSheet<void>(
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
                  Text('${r.id} · ${shortDate(r.time)}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Pal.of(sheetContext).ink)),
                  const Spacer(),
                  PressableScale(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    pressedScale: 0.85,
                    child: Icon(Icons.close,
                        size: 18,
                        color: Pal.of(sheetContext).muted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _reportRow(sheetContext, 'Cashier', r.cashier),
              _reportRow(
                  sheetContext, 'Transactions', '${r.transactions}'),
              _reportRow(
                  sheetContext, 'Items sold', '${r.itemsSold}'),
              _reportRow(sheetContext, 'Gross sales',
                  money(r.grossSales)),
              _reportRow(sheetContext, 'Net sales', money(r.netSales),
                  bold: true),
              _reportRow(sheetContext, 'Cash in drawer',
                  money(r.expectedDrawer)),
              _reportRow(sheetContext, 'Counted cash',
                  money(r.countedCash)),
              _reportRow(sheetContext, 'Variance',
                  r.variance == 0
                      ? 'Balanced'
                      : '${r.variance > 0 ? '+' : '-'}${money(r.variance.abs())}',
                  bold: true,
                  valueColor: r.variance == 0
                      ? Pal.of(sheetContext).sage
                      : Pal.of(sheetContext).danger),
              if (r.note.isNotEmpty)
                _reportRow(sheetContext, 'Note', r.note),
            ],
          ),
        ),
      ),
    );
  }
}
