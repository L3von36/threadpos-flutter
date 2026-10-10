import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

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
        const SizedBox(height: 8),
        StaggerIn(
          index: 1,
          dy: 10,
          child: const _DailySalesSummaryCard(),
        ),
        const SectionHeader(title: 'Key metrics'),
        StaggerIn(
          index: 2,
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
          child: const _FlChartRevenueWidget(),
        ),
        const SectionHeader(title: 'Inventory alerts'),
        StaggerIn(
          index: 4,
          dy: 10,
          child: const _LowStockAlertsWidget(),
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

class _DailySalesSummaryCard extends StatelessWidget {
  const _DailySalesSummaryCard();

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final List<Sale> todaySales = store.todaySales;
    final double revenue = store.todayRevenue;
    final int txCount = todaySales.length;
    final List<TopProduct> topToday = store.topProductsFor(todaySales);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        border: Border.all(color: pal.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: pal.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.today, size: 17, color: pal.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Daily Sales Summary',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: pal.ink)),
                    Text('Today\'s live store activity',
                        style: TextStyle(fontSize: 11, color: pal.muted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pal.sage.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$txCount txns',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: pal.sage)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('REVENUE',
                        style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: pal.muted)),
                    const SizedBox(height: 2),
                    Text(money(revenue),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: pal.ink)),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: pal.border),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('ITEMS SOLD',
                        style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: pal.muted)),
                    const SizedBox(height: 2),
                    Text('${store.todayItems} units',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: pal.ink)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: pal.border, height: 1),
          const SizedBox(height: 10),
          Text('Top-selling items today',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: pal.ink)),
          const SizedBox(height: 6),
          if (topToday.isEmpty)
            Text('No sales recorded today yet.',
                style: TextStyle(fontSize: 11, color: pal.muted))
          else
            ...topToday.take(3).map((TopProduct tp) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: pal.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tp.product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: pal.ink)),
                      ),
                      Text('${tp.qty} sold · ${money(tp.revenue)}',
                          style: TextStyle(
                              fontSize: 11, color: pal.muted)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _FlChartRevenueWidget extends StatefulWidget {
  const _FlChartRevenueWidget();

  @override
  State<_FlChartRevenueWidget> createState() => _FlChartRevenueWidgetState();
}

class _FlChartRevenueWidgetState extends State<_FlChartRevenueWidget> {
  int _days = 7;
  DateTimeRange? _customRange;

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(Duration(days: _days - 1)),
            end: now,
          ),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);

    final List<double> revs;
    final List<String> labels;
    final String rangeTitle;

    if (_customRange != null) {
      final DateTime start = _customRange!.start;
      final DateTime end = _customRange!.end;
      final int diffDays = end.difference(start).inDays + 1;
      final int totalDays = diffDays < 1 ? 1 : (diffDays > 90 ? 90 : diffDays);

      revs = List<double>.filled(totalDays, 0);
      labels = <String>[];
      final DateTime dayStart = DateTime(start.year, start.month, start.day);

      for (final Sale s in store.sales) {
        final DateTime sDate = DateTime(s.time.year, s.time.month, s.time.day);
        final int dIndex = sDate.difference(dayStart).inDays;
        if (dIndex >= 0 && dIndex < totalDays) {
          revs[dIndex] += s.total;
        }
      }
      for (int i = 0; i < totalDays; i++) {
        final DateTime d = dayStart.add(Duration(days: i));
        labels.add('${d.month}/${d.day}');
      }
      rangeTitle = '${start.month}/${start.day} - ${end.month}/${end.day}';
    } else {
      revs = store.revenueByDay(_days);
      labels = <String>[
        for (int i = 0; i < _days; i++)
          _dayName(DateTime.now().subtract(Duration(days: _days - 1 - i)).weekday)
      ];
      rangeTitle = 'Last $_days days';
    }

    final double maxRev = revs.fold(0.0, (double m, double v) => v > m ? v : m);
    final double maxY = maxRev <= 0 ? 10000 : maxRev * 1.2;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Revenue Trend',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: pal.ink)),
                  const SizedBox(height: 1),
                  Text(rangeTitle,
                      style: TextStyle(fontSize: 11, color: pal.muted)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (_customRange == null) ...<Widget>[
                    _pillBtn('7D', 7, pal),
                    const SizedBox(width: 4),
                    _pillBtn('30D', 30, pal),
                    const SizedBox(width: 4),
                  ] else ...<Widget>[
                    GestureDetector(
                      onTap: () => setState(() => _customRange = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: pal.surfaceAlt,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Clear custom',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: pal.accent)),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  PressableScale(
                    onTap: () => _pickDateRange(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _customRange != null
                            ? pal.accent
                            : pal.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.date_range_outlined,
                          size: 16,
                          color: _customRange != null
                              ? Colors.white
                              : pal.ink),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (double value) => FlLine(
                    color: pal.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          value >= 1000
                              ? '${(value / 1000).toStringAsFixed(0)}k'
                              : '${value.toInt()}',
                          style: TextStyle(fontSize: 9, color: pal.muted),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const Text('');
                        }
                        if (labels.length > 10 &&
                            index % (labels.length ~/ 5 + 1) != 0) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[index],
                            style: TextStyle(
                                fontSize: labels.length > 10 ? 8 : 10,
                                fontWeight: FontWeight.w600,
                                color: pal.muted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (labels.length - 1).toDouble() <= 0
                    ? 1
                    : (labels.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: <FlSpot>[
                      for (int i = 0; i < revs.length; i++)
                        FlSpot(i.toDouble(), revs[i]),
                    ],
                    isCurved: true,
                    color: pal.accent,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: labels.length <= 15,
                      getDotPainter: (FlSpot spot, double x,
                              LineChartBarData barData, int index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: pal.surface,
                        strokeWidth: 2,
                        strokeColor: pal.accent,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: pal.accent.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillBtn(String label, int d, Pal pal) {
    final bool active = _days == d && _customRange == null;
    return GestureDetector(
      onTap: () => setState(() {
        _days = d;
        _customRange = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? pal.accent : pal.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : pal.muted)),
      ),
    );
  }

  String _dayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}

class _LowStockAlertsWidget extends StatelessWidget {
  const _LowStockAlertsWidget();

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final List<Product> lowStockItems = store.lowStockProducts;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        border: Border.all(
          color: lowStockItems.isNotEmpty
              ? pal.danger.withValues(alpha: 0.3)
              : pal.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (lowStockItems.isNotEmpty ? pal.danger : pal.sage)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  lowStockItems.isNotEmpty
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  size: 17,
                  color: lowStockItems.isNotEmpty ? pal.danger : pal.sage,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Inventory Alert System',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: pal.ink)),
                    Text(
                      lowStockItems.isNotEmpty
                          ? '${lowStockItems.length} items below threshold (≤ 5 units)'
                          : 'All inventory levels healthy',
                      style: TextStyle(
                        fontSize: 11,
                        color: lowStockItems.isNotEmpty
                            ? pal.danger
                            : pal.muted,
                        fontWeight: lowStockItems.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (lowStockItems.isNotEmpty) ...<Widget>[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pal.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${lowStockItems.length} alerts',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: pal.danger)),
                ),
                const SizedBox(width: 6),
              ],
              PressableScale(
                onTap: () => _showQuickAddStockModal(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: pal.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.add, size: 14, color: Colors.white),
                      const SizedBox(width: 3),
                      Text('Quick Add',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lowStockItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('No low stock or out of stock items detected.',
                  style: TextStyle(fontSize: 12, color: pal.muted)),
            )
          else ...<Widget>[
            Divider(color: pal.border, height: 1),
            const SizedBox(height: 10),
            ...lowStockItems.take(4).map((Product p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 30,
                          height: 30,
                          color: pal.surfaceAlt,
                          child: p.imageUrl.isNotEmpty
                              ? Image.network(p.imageUrl, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                      Icons.image_not_supported,
                                      size: 14,
                                      color: pal.muted))
                              : Icon(Icons.checkroom,
                                  size: 14, color: pal.muted),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: pal.ink)),
                            Text('${p.category} · ${money(p.price)}',
                                style: TextStyle(
                                    fontSize: 11, color: pal.muted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: (p.isOutOfStock ? pal.danger : pal.amber)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          p.isOutOfStock ? 'Out of stock' : '${p.stock} left',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: p.isOutOfStock ? pal.danger : pal.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

void _showQuickAddStockModal(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return ChangeNotifierProvider<Store>.value(
        value: context.read<Store>(),
        child: const _QuickAddStockSheet(),
      );
    },
  );
}

class _QuickAddStockSheet extends StatefulWidget {
  const _QuickAddStockSheet();

  @override
  State<_QuickAddStockSheet> createState() => _QuickAddStockSheetState();
}

class _QuickAddStockSheetState extends State<_QuickAddStockSheet> {
  Product? _selectedProduct;
  final TextEditingController _qtyController = TextEditingController(text: '10');
  String _searchQuery = '';

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final List<Product> filteredProducts = store.products
        .where((Product p) =>
            _searchQuery.isEmpty ||
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.category.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.inventory_2_outlined, size: 20, color: pal.accent),
              const SizedBox(width: 10),
              Text('Quick Add Stock',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: pal.ink)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Select an existing item and add incoming shipment or restock units.',
              style: TextStyle(fontSize: 12, color: pal.muted)),
          const SizedBox(height: 12),
          TextField(
            onChanged: (String q) => setState(() => _searchQuery = q),
            decoration: AppTheme.input(context, 'Search catalog items...',
                icon: Icons.search),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: filteredProducts.isEmpty
                ? Center(
                    child: Text('No products found',
                        style: TextStyle(color: pal.muted)))
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (BuildContext context, int i) {
                      final Product p = filteredProducts[i];
                      final bool selected = _selectedProduct?.id == p.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedProduct = p),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: selected ? pal.softAccent : pal.surface,
                            borderRadius: BorderRadius.circular(AppTheme.rMd),
                            border: Border.all(
                              color: selected ? pal.accent : pal.border,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(p.name,
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: pal.ink)),
                                    Text(
                                        '${p.category} · ${p.stock} in stock',
                                        style: TextStyle(
                                            fontSize: 11, color: pal.muted)),
                                  ],
                                ),
                              ),
                              if (selected)
                                Icon(Icons.check_circle,
                                    size: 18, color: pal.accent),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          if (_selectedProduct != null) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Add to ${_selectedProduct!.name}',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: pal.ink),
                  ),
                ),
                Text('Current: ${_selectedProduct!.stock}',
                    style: TextStyle(fontSize: 11, color: pal.muted)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: AppTheme.input(context, 'Quantity to add',
                        icon: Icons.add),
                  ),
                ),
                const SizedBox(width: 8),
                PressableScale(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: pal.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onPressed: () {
                      final int? qty =
                          int.tryParse(_qtyController.text.trim());
                      if (qty == null || qty <= 0) {
                        showSnack(context, 'Enter a valid quantity');
                        return;
                      }
                      store.adjustStock(_selectedProduct!.id, qty);
                      Navigator.of(context).pop();
                      showSnack(
                          context,
                          'Added +$qty units to ${_selectedProduct!.name}');
                    },
                    child: const Text('Update Stock'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}




