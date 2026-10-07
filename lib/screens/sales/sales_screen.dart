import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import '../manager/manager_screens.dart';

/// Sales dashboard. Renders the seller shift view or the manager
/// analytics + control center depending on the active workspace role.
class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => _confirmLogout(context, store),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: store.isManager
          ? const _ManagerSalesView()
          : const _SellerSalesView(),
    );
  }

  Future<void> _confirmLogout(BuildContext context, Store store) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'You will return to the workspace selection screen.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Stay',
                style:
                    TextStyle(color: Pal.of(dialogContext).muted)),
          ),
          PressableScale(
            child: FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                store.logout();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (Route<dynamic> r) => false);
              },
              child: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seller view
// ---------------------------------------------------------------------------

class _SellerSalesView extends StatelessWidget {
  const _SellerSalesView();

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final double revenue = store.todayRevenue;
    final double progress =
        Store.shiftTarget <= 0 ? 0 : revenue / Store.shiftTarget;
    final double remaining =
        revenue >= Store.shiftTarget ? 0 : Store.shiftTarget - revenue;
    final Map<PaymentMethod, double> mix = store.paymentMix;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
      children: <Widget>[
        StaggerIn(
          index: 0,
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
                          '${v.round()}% · ${money(revenue)}',
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
        const SectionHeader(title: 'Today'),
        StaggerIn(
          index: 1,
          dy: 10,
          child: Row(
            children: <Widget>[
              Expanded(
                child: StatCard(
                    label: 'Sales',
                    value: money(revenue),
                    icon: Icons.point_of_sale),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                    label: 'Transactions',
                    value: '${store.todaySales.length}',
                    icon: Icons.receipt_long,
                    color: pal.sage),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                    label: 'Items',
                    value: '${store.todayItems}',
                    icon: Icons.local_mall_outlined,
                    color: pal.amber),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Payment mix'),
        StaggerIn(
          index: 2,
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
                for (final PaymentMethod m in PaymentMethod.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MixRow(
                        label: paymentMethodLabel(m),
                        amount: mix[m] ?? 0,
                        total: revenue),
                  ),
              ],
            ),
          ),
        ),
        const SectionHeader(title: 'Recent sales'),
        if (store.todaySales.isEmpty)
          Text('No sales yet today.',
              style: TextStyle(fontSize: 12, color: pal.muted))
        else
          ...store.todaySales.take(5).toList().asMap().entries.map(
                (MapEntry<int, Sale> entry) => StaggerIn(
                  index: 3 + entry.key,
                  dy: 8,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: pal.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.rMd),
                      border: Border.all(color: pal.border),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(paymentMethodIcon(entry.value.method),
                            size: 17, color: pal.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                  '#${entry.value.id} · ${clockLabel(entry.value.time)}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                      color: pal.ink)),
                              Text(
                                  '${entry.value.itemCount} item(s) · ${entry.value.seller}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: pal.muted)),
                            ],
                          ),
                        ),
                        Text(money(entry.value.total),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: pal.ink)),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class _MixRow extends StatelessWidget {
  const _MixRow(
      {required this.label, required this.amount, required this.total});

  final String label;
  final double amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    final double frac = total <= 0 ? 0 : amount / total;
    return Row(
      children: <Widget>[
        SizedBox(
            width: 48,
            child: Text(label,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: pal.ink))),
        const SizedBox(width: 8),
        Expanded(child: ProgressBar(value: frac)),
        const SizedBox(width: 8),
        SizedBox(
          width: 42,
          child: Text('${(frac * 100).round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: pal.muted)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Manager view
// ---------------------------------------------------------------------------

class _ManagerSalesView extends StatelessWidget {
  const _ManagerSalesView();

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final double revenue = store.todayRevenue;
    final int transactions = store.todaySales.length;
    final double avg =
        transactions == 0 ? 0 : revenue / transactions;
    final List<double> hours = store.revenueByHour;
    final double maxHour =
        hours.fold(0.0, (double m, double v) => v > m ? v : m);
    final List<MapEntry<Product, int>> top = store.topProducts;
    final int maxTop = top.isEmpty
        ? 1
        : top.map((MapEntry<Product, int> e) => e.value).reduce(
            (int a, int b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
      children: <Widget>[
        StaggerIn(
          index: 0,
          dy: 10,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: pal.bannerBg,
              borderRadius: BorderRadius.circular(AppTheme.rLg),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Manager dashboard',
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: pal.bannerText)),
                      const SizedBox(height: 3),
                      Text(
                          'Live performance across the floor today.',
                          style: TextStyle(
                              fontSize: 11.5, color: pal.bannerSub)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('Today',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: pal.bannerText)),
                ),
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
                    label: 'Revenue',
                    value: money(revenue),
                    icon: Icons.payments_outlined),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                    label: 'Transactions',
                    value: '$transactions',
                    icon: Icons.receipt_long,
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
                    label: 'Avg ticket',
                    value: money(avg),
                    icon: Icons.confirmation_number_outlined,
                    color: pal.amber),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                    label: 'Items sold',
                    value: '${store.todayItems}',
                    icon: Icons.local_mall_outlined,
                    color: pal.accentDeep),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Sales by hour'),
        StaggerIn(
          index: 3,
          dy: 10,
          child: Container(
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
                      for (int i = 0; i < hours.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 1.5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                    begin: 2,
                                    end: maxHour <= 0
                                        ? 2
                                        : 6 + (hours[i] / maxHour) * 94,
                                  ),
                                  duration: Motion.slow +
                                      Duration(
                                          milliseconds: i * 24),
                                  curve: Motion.out,
                                  builder: (BuildContext context,
                                          double h, _) =>
                                      Container(
                                    height: h,
                                    decoration: BoxDecoration(
                                      color: hours[i] > 0
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
                    for (int i = 0; i < hours.length; i++)
                      Expanded(
                        child: Text(
                          i % 2 == 0 ? hourLabel(9 + i) : '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 9, color: pal.muted),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SectionHeader(title: 'Top products today'),
        if (top.isEmpty)
          Text('No sales recorded yet today.',
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
                              color: pal.surfaceAlt,
                              shape: BoxShape.circle,
                            ),
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: pal.ink)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(top[i].key.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: pal.ink)),
                                const SizedBox(height: 3),
                                ProgressBar(
                                  value: top[i].value / maxTop,
                                  height: 5,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${top[i].value} sold',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: pal.muted)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SectionHeader(title: 'Control center'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: <Widget>[
            StaggerIn(
              index: 5,
              dy: 10,
              child: _ModuleCard(
                  title: 'Employees',
                  subtitle: 'Team & commissions',
                  icon: Icons.groups_outlined,
                  screen: const EmployeesScreen()),
            ),
            StaggerIn(
              index: 6,
              dy: 10,
              child: _ModuleCard(
                  title: 'Branches',
                  subtitle: 'Revenue vs target',
                  icon: Icons.store_outlined,
                  screen: const BranchesScreen()),
            ),
            StaggerIn(
              index: 7,
              dy: 10,
              child: _ModuleCard(
                  title: 'Scheduling',
                  subtitle: 'Weekly shifts',
                  icon: Icons.calendar_month_outlined,
                  screen: const ScheduleScreen()),
            ),
            StaggerIn(
              index: 8,
              dy: 10,
              child: _ModuleCard(
                  title: 'Performance',
                  subtitle: 'Seller leaderboard',
                  icon: Icons.trending_up,
                  screen: const PerformanceScreen()),
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 19, color: pal.accent),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: pal.ink)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 10.5, color: pal.muted)),
          ],
        ),
      ),
    );
  }
}
