import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
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
            icon: const Icon(Icons.logout),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?'),
        content: const Text(
            'You will return to the workspace selection screen.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child:
                const Text('Stay', style: TextStyle(color: AppTheme.muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              store.logout();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (Route<dynamic> r) => false);
            },
            child: const Text('Sign out'),
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
    final double revenue = store.todayRevenue;
    final double progress =
        Store.shiftTarget <= 0 ? 0 : revenue / Store.shiftTarget;
    final double remaining =
        revenue >= Store.shiftTarget ? 0 : Store.shiftTarget - revenue;
    final Map<PaymentMethod, double> mix = store.paymentMix;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text('Shift target',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink)),
                  Text(
                      '${(progress * 100).round()}% · ${money(revenue)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.terracotta)),
                ],
              ),
              const SizedBox(height: 12),
              ProgressBar(value: progress, height: 10),
              const SizedBox(height: 10),
              Text(
                remaining > 0
                    ? '${money(remaining)} to go · target ${money(Store.shiftTarget)}'
                    : 'Target reached — great work!',
                style: const TextStyle(
                    fontSize: 12.5, color: AppTheme.muted),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Today'),
        Row(
          children: <Widget>[
            Expanded(
              child: StatCard(
                  label: 'Sales',
                  value: money(revenue),
                  icon: Icons.point_of_sale),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                  label: 'Transactions',
                  value: '${store.todaySales.length}',
                  icon: Icons.receipt_long,
                  color: AppTheme.sage),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                  label: 'Items',
                  value: '${store.todayItems}',
                  icon: Icons.local_mall_outlined,
                  color: AppTheme.amber),
            ),
          ],
        ),
        const SectionHeader(title: 'Payment mix'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: <Widget>[
              for (final PaymentMethod m in PaymentMethod.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MixRow(
                      label: paymentMethodLabel(m),
                      amount: mix[m] ?? 0,
                      total: revenue),
                ),
            ],
          ),
        ),
        const SectionHeader(title: 'Recent sales'),
        if (store.todaySales.isEmpty)
          const Text('No sales yet today.',
              style: TextStyle(fontSize: 13, color: AppTheme.muted))
        else
          ...store.todaySales.take(5).map(
                (Sale s) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(paymentMethodIcon(s.method),
                          size: 20, color: AppTheme.terracotta),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('#${s.id} · ${clockLabel(s.time)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: AppTheme.ink)),
                            Text(
                                '${s.itemCount} item(s) · ${s.seller}',
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.muted)),
                          ],
                        ),
                      ),
                      Text(money(s.total),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: AppTheme.ink)),
                    ],
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
    final double frac = total <= 0 ? 0 : amount / total;
    return Row(
      children: <Widget>[
        SizedBox(
            width: 52,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink))),
        const SizedBox(width: 10),
        Expanded(child: ProgressBar(value: frac)),
        const SizedBox(width: 10),
        SizedBox(
          width: 46,
          child: Text('${(frac * 100).round()}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.muted)),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.ink,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: <Widget>[
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Manager dashboard',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    SizedBox(height: 4),
                    Text(
                        'Live performance across the floor today.',
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.white60)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('Today',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Key metrics'),
        Row(
          children: <Widget>[
            Expanded(
              child: StatCard(
                  label: 'Revenue',
                  value: money(revenue),
                  icon: Icons.payments_outlined),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                  label: 'Transactions',
                  value: '$transactions',
                  icon: Icons.receipt_long,
                  color: AppTheme.sage),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: StatCard(
                  label: 'Avg ticket',
                  value: money(avg),
                  icon: Icons.confirmation_number_outlined,
                  color: AppTheme.amber),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                  label: 'Items sold',
                  value: '${store.todayItems}',
                  icon: Icons.local_mall_outlined,
                  color: AppTheme.terracottaDark),
            ),
          ],
        ),
        const SectionHeader(title: 'Sales by hour'),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    for (int i = 0; i < hours.length; i++)
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Container(
                                height: maxHour <= 0
                                    ? 2
                                    : 8 + (hours[i] / maxHour) * 120,
                                decoration: BoxDecoration(
                                  color: hours[i] > 0
                                      ? AppTheme.terracotta
                                      : AppTheme.creamDeep,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  for (int i = 0; i < hours.length; i++)
                    Expanded(
                      child: Text(
                        i % 2 == 0 ? hourLabel(9 + i) : '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 9.5, color: AppTheme.muted),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Top products today'),
        if (top.isEmpty)
          const Text('No sales recorded yet today.',
              style: TextStyle(fontSize: 13, color: AppTheme.muted))
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < top.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppTheme.creamDeep,
                            shape: BoxShape.circle,
                          ),
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(top[i].key.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.ink)),
                              const SizedBox(height: 4),
                              ProgressBar(
                                value: top[i].value / maxTop,
                                height: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${top[i].value} sold',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.muted)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SectionHeader(title: 'Control center'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: const <Widget>[
            _ModuleCard(
                title: 'Employees',
                subtitle: 'Team & commissions',
                icon: Icons.groups_outlined,
                screen: EmployeesScreen()),
            _ModuleCard(
                title: 'Branches',
                subtitle: 'Revenue vs target',
                icon: Icons.store_outlined,
                screen: BranchesScreen()),
            _ModuleCard(
                title: 'Scheduling',
                subtitle: 'Weekly shifts',
                icon: Icons.calendar_month_outlined,
                screen: ScheduleScreen()),
            _ModuleCard(
                title: 'Performance',
                subtitle: 'Seller leaderboard',
                icon: Icons.trending_up,
                screen: PerformanceScreen()),
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
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => screen),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 22, color: AppTheme.terracotta),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}
