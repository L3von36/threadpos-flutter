import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

// ---------------------------------------------------------------------------
// Branch analytics — network overview
// ---------------------------------------------------------------------------

class BranchesScreen extends StatelessWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final SalesRange range = SalesRange.today;

    final double networkRevenue = store.branches.fold(
        0.0, (double s, Branch b) => s + store.branchRevenue(b.name, range));
    final int networkOrders = store.branches.fold(
        0,
        (int s, Branch b) =>
            s + store.salesForBranch(b.name, range).length);
    final int networkUnits = store.branches.fold(
        0,
        (int s, Branch b) =>
            s + store.itemsFor(store.salesForBranch(b.name, range)));
    final double networkTarget = store.branches.fold(
        0.0, (double s, Branch b) => s + b.target);

    return Scaffold(
      appBar: AppBar(title: const Text('Branch analytics')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          StaggerIn(
            index: 0,
            dy: 8,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: pal.bannerBg,
                borderRadius: BorderRadius.circular(AppTheme.rLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('NETWORK · TODAY',
                      style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                          color: pal.bannerSub)),
                  const SizedBox(height: 5),
                  CountUpText(
                    networkRevenue,
                    style: TextStyle(
                        fontSize: 22,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        color: pal.bannerText),
                    formatter: money,
                  ),
                  const SizedBox(height: 5),
                  Text(
                      '${(networkTarget <= 0 ? 0 : networkRevenue / networkTarget * 100).round()}% of ${money(networkTarget)} network target',
                      style: TextStyle(
                          fontSize: 11.5, color: pal.bannerSub)),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Network KPIs'),
          StaggerIn(
            index: 1,
            dy: 8,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: StatCard(
                      label: 'Orders',
                      value: '$networkOrders',
                      icon: Icons.receipt_long),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                      label: 'Units sold',
                      value: '$networkUnits',
                      icon: Icons.local_mall_outlined,
                      color: pal.sage),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                      label: 'Avg. order',
                      value: money(networkOrders == 0
                          ? 0
                          : networkRevenue / networkOrders),
                      icon: Icons.confirmation_number_outlined,
                      color: pal.amber),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Branches'),
          ...store.branches
              .toList()
              .asMap()
              .entries
              .map((MapEntry<int, Branch> entry) {
            final Branch b = entry.value;
            final double revenue = store.branchRevenue(b.name, range);
            final double? prior = _priorBranchRevenue(store, b.name, range);
            final double? delta =
                prior == null || prior <= 0 ? null : (revenue - prior) / prior * 100;
            final int orders =
                store.salesForBranch(b.name, range).length;
            return StaggerIn(
              index: 2 + entry.key,
              dy: 8,
              child: PressableScale(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => BranchDetailScreen(branchName: b.name)),
                ),
                pressedScale: 0.97,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pal.surface,
                    borderRadius: BorderRadius.circular(AppTheme.rLg),
                    border: Border.all(color: pal.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(b.name,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: pal.ink)),
                          ),
                          if (delta != null)
                            StockBadge(
                              label:
                                  '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}% vs prev',
                              color:
                                  delta >= 0 ? pal.sage : pal.danger,
                            ),
                          const SizedBox(width: 6),
                          StockBadge(
                              label: '${b.staff} staff', color: pal.accent),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text('Manager · ${b.manager}',
                          style: TextStyle(
                              fontSize: 11.5, color: pal.muted)),
                      const SizedBox(height: 10),
                      ProgressBar(value: b.progress, height: 7),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(money(revenue),
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: pal.accent)),
                          Text(
                              '$orders orders · target ${money(b.target)}',
                              style: TextStyle(
                                  fontSize: 11, color: pal.muted)),
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

  static double? _priorBranchRevenue(
      Store store, String branch, SalesRange range) {
    final DateTime now = DateTime.now();
    final DateTime dayStart = DateTime(now.year, now.month, now.day);
    final DateTime curStart =
        dayStart.subtract(Duration(days: range.days - 1));
    final DateTime prevEnd =
        curStart.subtract(const Duration(microseconds: 1));
    final DateTime prevStart =
        prevEnd.subtract(Duration(days: range.days - 1));
    double sum = 0;
    for (final Sale s in store.sales) {
      if (s.time.isAfter(prevStart) &&
          s.time.isBefore(prevEnd.add(const Duration(days: 1))) &&
          store.branchForSale(s) == branch) {
        sum += s.total;
      }
    }
    return sum;
  }
}

// ---------------------------------------------------------------------------
// Branch detail — full drill-down
// ---------------------------------------------------------------------------

class BranchDetailScreen extends StatelessWidget {
  const BranchDetailScreen({super.key, required this.branchName});

  final String branchName;

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final Branch branch = store.branches.firstWhere(
      (Branch b) => b.name == branchName,
      orElse: () => store.branches.first,
    );
    final List<Sale> sales = store.salesForBranch(branchName, SalesRange.today);
    final double revenue = store.revenueFor(sales);
    final int orders = sales.length;
    final int units = store.itemsFor(sales);
    final double avg = orders == 0 ? 0 : revenue / orders;
    final List<TopProduct> top = store.topProductsFor(sales);
    final double maxTop = top.isEmpty
        ? 1
        : top.map((TopProduct e) => e.qty).reduce(
            (int a, int b) => a > b ? a : b).toDouble();
    final List<Employee> staff = store.employees
        .where((Employee e) => e.branch == branchName)
        .toList()
      ..sort((Employee a, Employee b) =>
          b.todaySales.compareTo(a.todaySales));
    final List<double> week = _branchWeek(store, branchName);
    final double maxWeek = week.isEmpty
        ? 1
        : week.reduce((double a, double b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: Text(branchName)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          StaggerIn(
            index: 0,
            dy: 8,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: pal.bannerBg,
                borderRadius: BorderRadius.circular(AppTheme.rLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('TODAY · ${branch.manager}',
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
                  const SizedBox(height: 8),
                  ProgressBar(
                      value: branch.progress,
                      height: 7,
                      color: Colors.white,
                      track: Colors.white.withValues(alpha: 0.25)),
                  const SizedBox(height: 5),
                  Text(
                      '${(branch.progress * 100).round()}% of ${money(branch.target)} daily target',
                      style: TextStyle(
                          fontSize: 11.5, color: pal.bannerSub)),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Key metrics'),
          StaggerIn(
            index: 1,
            dy: 8,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: StatCard(
                      label: 'Orders',
                      value: '$orders',
                      icon: Icons.receipt_long),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                      label: 'Units',
                      value: '$units',
                      icon: Icons.local_mall_outlined,
                      color: pal.sage),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                      label: 'Avg. order',
                      value: money(avg),
                      icon: Icons.confirmation_number_outlined,
                      color: pal.amber),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Last 7 days'),
          StaggerIn(
            index: 2,
            dy: 8,
            child: Container(
              height: 110,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pal.surface,
                borderRadius: BorderRadius.circular(AppTheme.rLg),
                border: Border.all(color: pal.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  for (int i = 0; i < week.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Container(
                              height: week[i] <= 0
                                  ? 2
                                  : (week[i] / maxWeek) * 62,
                              decoration: BoxDecoration(
                                color: i == week.length - 1
                                    ? pal.accent
                                    : pal.softAccent,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text('D${i + 1}',
                                style: TextStyle(
                                    fontSize: 9, color: pal.muted)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'What is moving here'),
          if (top.isEmpty)
            Text('No sales recorded at this branch today.',
                style: TextStyle(fontSize: 12, color: pal.muted))
          else
            StaggerIn(
              index: 3,
              dy: 8,
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
          const SectionHeader(title: 'Staff leaderboard'),
          if (staff.isEmpty)
            Text('No team members assigned to this branch yet.',
                style: TextStyle(fontSize: 12, color: pal.muted))
          else ...staff
              .asMap()
              .entries
              .map((MapEntry<int, Employee> entry) => StaggerIn(
                    index: 4 + entry.key,
                    dy: 6,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 9),
                      decoration: BoxDecoration(
                        color: pal.surface,
                        borderRadius:
                            BorderRadius.circular(AppTheme.rMd),
                        border: Border.all(color: pal.border),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: entry.key == 0
                                  ? pal.amber
                                  : pal.surfaceAlt,
                              shape: BoxShape.circle,
                            ),
                            child: Text('${entry.key + 1}',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: entry.key == 0
                                        ? Colors.white
                                        : pal.ink)),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(entry.value.name,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: pal.ink)),
                          ),
                          Text(money(entry.value.todaySales),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: pal.accent)),
                        ],
                      ),
                    ),
                  )),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  static List<double> _branchWeek(Store store, String branch) {
    // Distribute the global 7-day revenue across branches with the
    // same weighting the network view uses (flagship-heavy).
    final List<double> global = store.revenueByDay(7);
    const List<double> shares = <double>[0.5, 0.3, 0.2];
    final int idx = Store.locations.indexOf(branch);
    final double share =
        idx < 0 || idx >= shares.length ? 0.2 : shares[idx];
    return global.map((double v) => v * share).toList();
  }
}
