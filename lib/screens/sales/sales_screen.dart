import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../notifications_screen.dart';
import '../../widgets/account_sheet.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import '../manager/approval_screens.dart';
import '../manager/branch_screens.dart';
import '../manager/employee_screens.dart';
import '../manager/finance_screens.dart';
import '../manager/manager_screens.dart';
import '../manager/performance_screens.dart';
import '../manager/report_screens.dart';

/// Sales dashboard. Renders the seller shift view or the manager
/// analytics + control center depending on the active workspace role,
/// both aware of the Today / 7 days / 30 days range.
class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: <Widget>[
          const NotificationsBell(),
          IconButton(
            tooltip: 'Workspace & sign out',
            icon: const Icon(Icons.switch_account_outlined, size: 20),
            onPressed: () => showAccountSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: store.isManager
          ? const _ManagerSalesView()
          : const _SellerSalesView(),
    );
  }
}

/// Segmented Today / 7 days / 30 days control.
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
        color: pal.surfaceAlt.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: SalesRange.values
            .map((SalesRange r) => GestureDetector(
                  onTap: () => onChanged(r),
                  child: AnimatedContainer(
                    duration: Motion.base,
                    curve: Motion.out,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 5),
                    decoration: BoxDecoration(
                      color: value == r ? pal.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(r.label,
                        style: TextStyle(
                            fontSize: 11,
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

/// Small "+18.4% vs previous period" caption.
class _DeltaCaption extends StatelessWidget {
  const _DeltaCaption({required this.delta});

  final double? delta;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    if (delta == null) {
      return Text('No previous period to compare',
          style: TextStyle(fontSize: 11, color: pal.muted));
    }
    final bool up = delta! >= 0;
    return Row(
      children: <Widget>[
        Icon(up ? Icons.trending_up : Icons.trending_down,
            size: 13, color: up ? pal.sage : pal.danger),
        const SizedBox(width: 4),
        Text(
          '${up ? '+' : ''}${delta!.toStringAsFixed(1)}% vs previous period',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: up ? pal.sage : pal.danger),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Seller view
// ---------------------------------------------------------------------------

class _SellerSalesView extends StatefulWidget {
  const _SellerSalesView();

  @override
  State<_SellerSalesView> createState() => _SellerSalesViewState();
}

class _SellerSalesViewState extends State<_SellerSalesView> {
  SalesRange _range = SalesRange.today;

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final List<Sale> sales = store.salesForRange(_range);
    final double revenue = store.revenueFor(sales);
    final int transactions = sales.length;
    final double avg = transactions == 0 ? 0 : revenue / transactions;
    final double progress =
        Store.shiftTarget <= 0 ? 0 : store.todayRevenue / Store.shiftTarget;
    final double remaining = store.todayRevenue >= Store.shiftTarget
        ? 0
        : Store.shiftTarget - store.todayRevenue;
    final double? delta = store.rangeDelta(_range);

    // Chart buckets: hourly for today, daily for the longer windows.
    final List<double> bars;
    final List<String> barLabels;
    if (_range == SalesRange.today) {
      bars = store.revenueByHour;
      barLabels = <String>[
        for (int i = 0; i < bars.length; i++)
          i % 2 == 0 ? hourLabel(9 + i) : '',
      ];
    } else {
      bars = store.revenueByDay(_range.days);
      barLabels = <String>[
        for (int i = 0; i < bars.length; i++)
          bars.length <= 7 || i % (bars.length ~/ 6 + 1) == 0
              ? '${DateTime.now().day - (bars.length - 1 - i)}'
              : '',
      ];
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
      children: <Widget>[
        Text('SELLER VIEW · CLOSE OF DAY',
            style: TextStyle(
                fontSize: 9.5,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w700,
                color: pal.accent)),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('Sales overview',
                style: AppTheme.pageTitle(context)),
            _RangeTabs(
              value: _range,
              onChanged: (SalesRange r) => setState(() => _range = r),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Net sales hero — the seller's close-of-day summary card.
        StaggerIn(
          index: 0,
          dy: 10,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: pal.bannerBg,
              borderRadius: BorderRadius.circular(AppTheme.rLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('NET SALES · ${_range.label.toUpperCase()}',
                    style: TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                        color: pal.bannerSub)),
                const SizedBox(height: 5),
                CountUpText(
                  revenue,
                  style: TextStyle(
                      fontSize: 22,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      color: pal.bannerText),
                  formatter: money,
                ),
                const SizedBox(height: 5),
                _DeltaCaption(delta: delta),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        StaggerIn(
          index: 1,
          dy: 10,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: pal.surface,
              borderRadius: BorderRadius.circular(AppTheme.rLg),
              border: Border.all(color: pal.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('Shift target',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: pal.ink)),
                    CountUpText(
                      progress * 100,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: pal.accent),
                      formatter: (double v) =>
                          '${v.round()}% · ${money(store.todayRevenue)}',
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ProgressBar(value: progress, height: 7),
                const SizedBox(height: 7),
                Text(
                  remaining > 0
                      ? '${money(remaining)} to go · target ${money(Store.shiftTarget)}'
                      : 'Target reached — great work!',
                  style:
                      TextStyle(fontSize: 11.5, color: pal.muted),
                ),
              ],
            ),
          ),
        ),
        const SectionHeader(title: 'Key metrics'),
        StaggerIn(
          index: 2,
          dy: 10,
          child: Row(
            children: <Widget>[
              Expanded(
                child: StatCard(
                    label: 'Transactions',
                    value: '$transactions',
                    icon: Icons.receipt_long),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                    label: 'Avg. order',
                    value: money(avg),
                    icon: Icons.confirmation_number_outlined,
                    color: pal.sage),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Revenue trend'),
        StaggerIn(
          index: 3,
          dy: 10,
          child: _RevenueBars(bars: bars, barLabels: barLabels),
        ),
        const SectionHeader(title: 'Recent sales'),
        if (sales.isEmpty)
          Text('No sales in this period.',
              style: TextStyle(fontSize: 12, color: pal.muted))
        else
          ...sales.take(6).toList().asMap().entries.map(
                (MapEntry<int, Sale> entry) => _SaleRow(
                  sale: entry.value,
                  index: 4 + entry.key,
                ),
              ),
      ],
    );
  }
}

/// Recent-sale row with a "Receipt" link, shared by both roles.
class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.sale, this.index = 0});

  final Sale sale;
  final int index;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return StaggerIn(
      index: index,
      dy: 8,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: pal.surface,
          borderRadius: BorderRadius.circular(AppTheme.rMd),
          border: Border.all(color: pal.border),
        ),
        child: Row(
          children: <Widget>[
            Icon(paymentMethodIcon(sale.method), size: 17, color: pal.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                      '#${sale.id} · ${clockLabel(sale.time)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: pal.ink)),
                  Text(
                      '${sale.itemCount} item(s) · ${sale.seller}',
                      style: TextStyle(
                          fontSize: 11, color: pal.muted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(money(sale.total),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: pal.ink)),
                GestureDetector(
                  onTap: () => showReceiptSheet(context, sale),
                  child: Text('Receipt',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: pal.accent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueBars extends StatelessWidget {
  const _RevenueBars({required this.bars, required this.barLabels});

  final List<double> bars;
  final List<String> barLabels;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    final double maxBar =
        bars.fold(0.0, (double m, double v) => v > m ? v : m);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        border: Border.all(color: pal.border),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (int i = 0; i < bars.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: bars.length > 12 ? 0.6 : 1.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 2,
                              end: maxBar <= 0
                                  ? 2
                                  : 6 + (bars[i] / maxBar) * 94,
                            ),
                            duration: Motion.slow +
                                Duration(
                                    milliseconds: i *
                                        (bars.length > 12 ? 6 : 24)),
                            curve: Motion.out,
                            builder: (BuildContext context,
                                    double h, _) =>
                                Container(
                              height: h,
                              decoration: BoxDecoration(
                                color: bars[i] > 0
                                    ? pal.accent
                                    : pal.surfaceAlt,
                                borderRadius:
                                    const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              for (int i = 0; i < bars.length; i++)
                Expanded(
                  child: Text(
                    barLabels[i],
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: bars.length > 12 ? 8 : 9,
                        color: pal.muted),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Manager view
// ---------------------------------------------------------------------------

class _ManagerSalesView extends StatefulWidget {
  const _ManagerSalesView();

  @override
  State<_ManagerSalesView> createState() => _ManagerSalesViewState();
}

class _ManagerSalesViewState extends State<_ManagerSalesView> {
  SalesRange _range = SalesRange.today;

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final List<Sale> sales = store.salesForRange(_range);
    final double revenue = store.revenueFor(sales);
    final int transactions = sales.length;
    final double avg = transactions == 0 ? 0 : revenue / transactions;
    final int units = store.itemsFor(sales);
    final double? delta = store.rangeDelta(_range);
    final List<TopProduct> top = store.topProductsFor(sales);
    final double maxTop = top.isEmpty
        ? 1
        : top.map((TopProduct e) => e.qty).reduce(
            (int a, int b) => a > b ? a : b).toDouble();

    // Chart buckets: hourly for today, daily for the longer windows.
    final List<double> bars;
    final List<String> barLabels;
    if (_range == SalesRange.today) {
      bars = store.revenueByHour;
      barLabels = <String>[
        for (int i = 0; i < bars.length; i++)
          i % 2 == 0 ? hourLabel(9 + i) : '',
      ];
    } else {
      bars = store.revenueByDay(_range.days);
      barLabels = <String>[
        for (int i = 0; i < bars.length; i++)
          bars.length <= 7 || i % (bars.length ~/ 6 + 1) == 0
              ? '${DateTime.now().day - (bars.length - 1 - i)}'
              : '',
      ];
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
      children: <Widget>[
        Text('MANAGER VIEW · PERFORMANCE',
            style: TextStyle(
                fontSize: 9.5,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w700,
                color: pal.accent)),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('Sales analytics',
                style: AppTheme.pageTitle(context)),
            _RangeTabs(
              value: _range,
              onChanged: (SalesRange r) => setState(() => _range = r),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Hero net-sales card.
        StaggerIn(
          index: 0,
          dy: 10,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: pal.bannerBg,
              borderRadius: BorderRadius.circular(AppTheme.rLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text('NET SALES · ${_range.label.toUpperCase()}',
                        style: TextStyle(
                            fontSize: 9.5,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                            color: pal.bannerSub)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: pal.sage.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                          delta != null && delta < 0
                              ? 'Off pace'
                              : 'On track',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                CountUpText(
                  revenue,
                  style: TextStyle(
                      fontSize: 22,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      color: pal.bannerText),
                  formatter: money,
                ),
                const SizedBox(height: 5),
                _DeltaCaption(delta: delta),
              ],
            ),
          ),
        ),
        const SectionHeader(title: 'Key metrics'),
        StaggerIn(
          index: 1,
          dy: 10,
          child: Row(
            children: <Widget>[
              Expanded(
                child: StatCard(
                    label: 'Orders',
                    value: '$transactions',
                    icon: Icons.receipt_long),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                    label: 'Avg. order',
                    value: money(avg),
                    icon: Icons.confirmation_number_outlined,
                    color: pal.sage),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        StaggerIn(
          index: 2,
          dy: 10,
          child: Row(
            children: <Widget>[
              Expanded(
                child: StatCard(
                    label: 'Units sold',
                    value: '$units',
                    icon: Icons.local_mall_outlined,
                    color: pal.amber),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                    label: 'Payment mix',
                    value:
                        '${((store.paymentMixFor(sales)[PaymentMethod.card] ?? 0) / (revenue <= 0 ? 1 : revenue) * 100).round()}% card',
                    icon: Icons.credit_card,
                    color: pal.accentDeep),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Revenue trend'),
        StaggerIn(
          index: 3,
          dy: 10,
          child: _RevenueBars(bars: bars, barLabels: barLabels),
        ),
        const SectionHeader(title: 'What is moving'),
        if (top.isEmpty)
          Text('No sales recorded in this period.',
              style: TextStyle(fontSize: 12, color: pal.muted))
        else
          StaggerIn(
            index: 4,
            dy: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pal.surface,
                borderRadius: BorderRadius.circular(AppTheme.rLg),
                border: Border.all(color: pal.border),
              ),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < top.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? pal.accent
                                  : pal.surfaceAlt,
                              shape: BoxShape.circle,
                            ),
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: i == 0
                                        ? Colors.white
                                        : pal.ink)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(top[i].product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: pal.ink)),
                                const SizedBox(height: 3),
                                ProgressBar(
                                  value: top[i].qty / maxTop,
                                  height: 5,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Text(money(top[i].revenue),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: pal.ink)),
                              Text('${top[i].qty} units',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: pal.muted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SectionHeader(title: 'Live feed'),
        if (sales.isEmpty)
          Text('No transactions in this period.',
              style: TextStyle(fontSize: 12, color: pal.muted))
        else
          ...sales.take(5).toList().asMap().entries.map(
                (MapEntry<int, Sale> entry) => _SaleRow(
                  sale: entry.value,
                  index: 5 + entry.key,
                ),
              ),
        const SectionHeader(title: 'Control center'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.55,
          children: <Widget>[
            StaggerIn(
              index: 6,
              dy: 10,
              child: _ModuleCard(
                  title: 'Employees',
                  subtitle: 'Team management',
                  icon: Icons.groups_outlined,
                  screen: const EmployeesScreen()),
            ),
            StaggerIn(
              index: 7,
              dy: 10,
              child: _ModuleCard(
                  title: 'Performance',
                  subtitle: 'Targets & rankings',
                  icon: Icons.trending_up,
                  screen: const PerformanceScreen()),
            ),
            StaggerIn(
              index: 8,
              dy: 10,
              child: _ModuleCard(
                  title: 'Branch analytics',
                  subtitle: 'Revenue vs target',
                  icon: Icons.store_outlined,
                  screen: const BranchesScreen()),
            ),
            StaggerIn(
              index: 9,
              dy: 10,
              child: _ModuleCard(
                  title: 'Approvals',
                  subtitle: 'Products & requests',
                  icon: Icons.how_to_reg_outlined,
                  badge: store.pendingProductCount +
                      store.approvals.length,
                  screen: const ApprovalsScreen()),
            ),
            StaggerIn(
              index: 10,
              dy: 10,
              child: _ModuleCard(
                  title: 'Expenses',
                  subtitle: 'Track spending',
                  icon: Icons.receipt_long,
                  screen: const ExpensesScreen()),
            ),
            StaggerIn(
              index: 11,
              dy: 10,
              child: _ModuleCard(
                  title: 'Income',
                  subtitle: 'P&L snapshot',
                  icon: Icons.savings_outlined,
                  screen: const IncomeScreen()),
            ),
            StaggerIn(
              index: 12,
              dy: 10,
              child: _ModuleCard(
                  title: 'X report',
                  subtitle: 'Mid-shift snapshot',
                  icon: Icons.print_outlined,
                  screen: const XReportScreen()),
            ),
            StaggerIn(
              index: 13,
              dy: 10,
              child: _ModuleCard(
                  title: 'Z report',
                  subtitle: 'Close of day',
                  icon: Icons.lock_outline,
                  badge: store.dayClosedToday ? 0 : 1,
                  screen: const ZReportScreen()),
            ),
            StaggerIn(
              index: 14,
              dy: 10,
              child: _ModuleCard(
                  title: 'Scheduling',
                  subtitle: 'Weekly shifts',
                  icon: Icons.calendar_month_outlined,
                  screen: const ScheduleScreen()),
            ),
            StaggerIn(
              index: 15,
              dy: 10,
              child: _ModuleCard(
                  title: 'Audit log',
                  subtitle: 'Team activity',
                  icon: Icons.fact_check_outlined,
                  screen: const AuditLogScreen()),
            ),
            StaggerIn(
              index: 16,
              dy: 10,
              child: _ModuleCard(
                  title: 'Cash registers',
                  subtitle: 'Open & close shifts',
                  icon: Icons.point_of_sale,
                  badge: 1,
                  screen: const RegistersScreen()),
            ),
            StaggerIn(
              index: 17,
              dy: 10,
              child: _ModuleCard(
                  title: 'Catalog & pricing',
                  subtitle: 'Pending updates',
                  icon: Icons.category_outlined,
                  badge: store.catalogUpdates.length,
                  screen: const CatalogUpdatesScreen()),
            ),
            StaggerIn(
              index: 18,
              dy: 10,
              child: _ModuleCard(
                  title: 'Alerts',
                  subtitle: 'Needs a look',
                  icon: Icons.notifications_active_outlined,
                  badge: store.alerts.length,
                  screen: const AlertsScreen()),
            ),
            StaggerIn(
              index: 19,
              dy: 10,
              child: _ModuleCard(
                  title: 'Offline sync',
                  subtitle: 'Queued uploads',
                  icon: Icons.cloud_sync_outlined,
                  badge: store.offlineQueue.length,
                  screen: const OfflineSyncScreen()),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.screen,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return PressableScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => screen),
      ),
      pressedScale: 0.95,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: pal.surface,
          borderRadius: BorderRadius.circular(AppTheme.rLg),
          border: Border.all(color: pal.border),
        ),
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 19, color: pal.accent),
                const SizedBox(height: 6),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: pal.ink)),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10.5, color: pal.muted)),
              ],
            ),
            if (badge != null && badge! > 0)
              Positioned(
                top: 0,
                right: 0,
                child: BumpOnChange(
                  trigger: badge!,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: pal.danger,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('${badge! > 9 ? '9+' : badge!}',
                        style: TextStyle(
                            fontSize: 9,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            color: pal.toastText)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
