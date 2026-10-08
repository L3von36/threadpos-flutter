import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/seed_data.dart';
import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

// ---------------------------------------------------------------------------
// Employees
// ---------------------------------------------------------------------------

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: store.employees.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int i) {
          final Employee e = store.employees[i];
          return StaggerIn(
            index: i,
            child: PressableScale(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => EmployeeDetailScreen(employee: e)),
              ),
              pressedScale: 0.97,
              child: Container(
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
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          pal.accent.withValues(alpha: 0.12),
                      child: Text(e.initial.toUpperCase(),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: pal.accent)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(e.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: pal.ink)),
                        Text('${e.title} · ${e.branch}',
                            style: TextStyle(
                                fontSize: 11.5, color: pal.muted)),
                        const SizedBox(height: 2),
                        Text(e.shift,
                            style: TextStyle(
                                fontSize: 10.5, color: pal.muted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(money(e.todaySales),
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: pal.ink)),
                      Text('${e.orders} orders',
                          style: TextStyle(
                              fontSize: 10.5, color: pal.sage)),
                    ],
                  ),
                  Icon(Icons.chevron_right,
                      size: 17, color: pal.muted),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Branches
// ---------------------------------------------------------------------------

class BranchesScreen extends StatelessWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Branches')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: store.branches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 9),
        itemBuilder: (BuildContext context, int i) {
          final Branch b = store.branches[i];
          return StaggerIn(
            index: i,
            child: Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(b.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: pal.ink)),
                      ),
                      StockBadge(
                          label: '${b.staff} staff',
                          color: pal.sage),
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
                      Text(money(b.revenue),
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: pal.accent)),
                      Text('target ${money(b.target)}',
                          style: TextStyle(
                              fontSize: 11, color: pal.muted)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scheduling
// ---------------------------------------------------------------------------

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  static const List<String> _dayNames = <String>[
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final int today = DateTime.now().weekday;

    return Scaffold(
      appBar: AppBar(title: const Text('Scheduling')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          for (int day = 1; day <= 7; day++)
            if (store.schedule
                .any((ShiftSlot s) => s.day == day)) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 7),
                child: Row(
                  children: <Widget>[
                    Text(_dayNames[day],
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: day == today
                                ? pal.accent
                                : pal.ink)),
                    if (day == today) ...<Widget>[
                      const SizedBox(width: 7),
                      StockBadge(
                          label: 'Today', color: pal.accent),
                    ],
                  ],
                ),
              ),
              ...store.schedule
                  .where((ShiftSlot s) => s.day == day)
                  .toList()
                  .asMap()
                  .entries
                  .map((MapEntry<int, ShiftSlot> entry) => StaggerIn(
                        index: day + entry.key,
                        dy: 8,
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
                              Icon(Icons.access_time,
                                  size: 14, color: pal.muted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(entry.value.name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                        color: pal.ink)),
                              ),
                              Text(entry.value.time,
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: pal.muted)),
                            ],
                          ),
                        ),
                      )),
            ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Performance
// ---------------------------------------------------------------------------

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final List<Employee> ranked = <Employee>[...store.employees]
      ..sort((Employee a, Employee b) => b.todaySales.compareTo(a.todaySales));
    final double maxSales =
        ranked.isEmpty ? 1 : ranked.first.todaySales;

    return Scaffold(
      appBar: AppBar(title: const Text('Performance')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          StaggerIn(
            index: 0,
            dy: 8,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pal.surfaceAlt.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.rMd),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.emoji_events_outlined,
                      size: 17, color: pal.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Commission rate 3% · daily target ${money(Store.shiftTarget)}',
                      style:
                          TextStyle(fontSize: 12, color: pal.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < ranked.length; i++)
            StaggerIn(
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
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              i == 0 ? pal.amber : pal.surfaceAlt,
                          shape: BoxShape.circle,
                        ),
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: i == 0
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
                                child: Text(ranked[i].name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: pal.ink)),
                              ),
                              Text(money(ranked[i].todaySales),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: pal.accent)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ProgressBar(
                              value: maxSales <= 0
                                  ? 0
                                  : ranked[i].todaySales / maxSales,
                              height: 5),
                        ],
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
}

// ---------------------------------------------------------------------------
// Employee detail + commission calculator
// ---------------------------------------------------------------------------

class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({super.key, required this.employee});

  final Employee employee;

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  double _rate = 3;

  static const List<double> _rates = <double>[3, 5, 7, 10];

  @override
  Widget build(BuildContext context) {
    final Employee e = widget.employee;
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(e.name)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          StaggerIn(
            index: 0,
            dy: 8,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pal.surface,
                borderRadius: BorderRadius.circular(AppTheme.rLg),
                border: Border.all(color: pal.border),
              ),
              child: Row(
                children: <Widget>[
                  PopIn(
                    begin: 0.6,
                    duration: Motion.base,
                    child: CircleAvatar(
                      radius: 21,
                      backgroundColor: pal.accent.withValues(alpha: 0.12),
                      child: Text(e.initial.toUpperCase(),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: pal.accent)),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(e.title,
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: pal.ink)),
                        Text('${e.branch} · ${e.shift}',
                            style: TextStyle(
                                fontSize: 11, color: pal.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Today at a glance'),
          StaggerIn(
            index: 1,
            dy: 8,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: StatCard(
                      label: 'Net sales',
                      value: money(e.todaySales),
                      icon: Icons.payments_outlined),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                      label: 'Orders',
                      value: '${e.orders}',
                      icon: Icons.receipt_long,
                      color: pal.sage),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                      label: 'Conversion',
                      value: '${e.conversion}%',
                      icon: Icons.percent,
                      color: pal.amber),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Commission calculator'),
          StaggerIn(
            index: 2,
            dy: 8,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pal.surface,
                borderRadius: BorderRadius.circular(AppTheme.rLg),
                border: Border.all(color: pal.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Commission rate',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: pal.ink)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _rates
                        .map((double r) => PressableScale(
                              onTap: () => setState(() => _rate = r),
                              pressedScale: 0.92,
                              child: AnimatedContainer(
                                duration: Motion.base,
                                curve: Motion.out,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _rate == r
                                      ? pal.accent
                                      : pal.surfaceAlt
                                          .withValues(alpha: 0.5),
                                  borderRadius:
                                      BorderRadius.circular(999),
                                ),
                                child: Text('${r.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _rate == r
                                            ? Colors.white
                                            : pal.ink)),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('${_rate.toStringAsFixed(0)}% of net sales',
                          style: TextStyle(
                              fontSize: 12, color: pal.muted)),
                      CountUpText(
                        e.commissionAt(_rate),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: pal.sage),
                        formatter: money,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Team at a glance'),
          ...store.employees
              .where((Employee other) => other.name != e.name)
              .toList()
              .asMap()
              .entries
              .map((MapEntry<int, Employee> entry) => StaggerIn(
                    index: 3 + entry.key,
                    dy: 6,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 8),
                      decoration: BoxDecoration(
                        color: pal.surface,
                        borderRadius:
                            BorderRadius.circular(AppTheme.rMd),
                        border: Border.all(color: pal.border),
                      ),
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 12,
                            backgroundColor:
                                pal.surfaceAlt,
                            child: Text(
                                entry.value.initial.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: pal.ink)),
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
                                  color: pal.muted)),
                        ],
                      ),
                    ),
                  )),
          const SizedBox(height: 10),
          PressableScale(
            child: OutlinedButton.icon(
              onPressed: () {
                showSnack(context,
                    'Team management is demo-only in this build');
              },
              icon: const Icon(Icons.manage_accounts_outlined, size: 17),
              label: const Text('Manage team'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Approvals
// ---------------------------------------------------------------------------

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  final List<OpsItem> _pending = List<OpsItem>.from(seedApprovals);

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: _pending.isEmpty
          ? const EmptyState(
              icon: Icons.task_alt,
              title: 'All clear',
              subtitle: 'No requests are waiting on a decision.')
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _pending.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int i) {
                final OpsItem item = _pending[i];
                return StaggerIn(
                  index: i,
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: pal.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.rMd),
                      border: Border.all(color: pal.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: pal.accent
                                    .withValues(alpha: 0.11),
                                borderRadius:
                                    BorderRadius.circular(9),
                              ),
                              child: Icon(item.icon,
                                  size: 16, color: pal.accent),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(item.title,
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: pal.ink)),
                                  Text(item.subtitle,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: pal.muted)),
                                ],
                              ),
                            ),
                            Text(item.meta,
                                style: TextStyle(
                                    fontSize: 10, color: pal.muted)),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: PressableScale(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize:
                                        const Size.fromHeight(34),
                                    side: BorderSide(
                                        color: pal.danger
                                            .withValues(alpha: 0.6)),
                                    foregroundColor: pal.danger,
                                  ),
                                  onPressed: () => _decide(context, i,
                                      approved: false),
                                  child: const Text('Decline'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: PressableScale(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    minimumSize:
                                        const Size.fromHeight(34),
                                    backgroundColor: pal.sage,
                                  ),
                                  onPressed: () => _decide(context, i,
                                      approved: true),
                                  child: const Text('Approve'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _decide(BuildContext context, int index, {required bool approved}) {
    final OpsItem item = _pending[index];
    setState(() => _pending.removeAt(index));
    showSnack(context,
        '${item.title} ${approved ? 'approved' : 'declined'}');
  }
}

// ---------------------------------------------------------------------------
// Ops list screens (audit log, registers, catalog, alerts, offline sync)
// ---------------------------------------------------------------------------

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: _OpsList(items: store.auditLog, live: true),
    );
  }
}

class RegistersScreen extends StatelessWidget {
  const RegistersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cash registers')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          StaggerIn(
            index: 0,
            child: _RegisterCard(
              name: 'Register 1 · Bole Flagship',
              status: 'Open since 09:02 · needs close',
              drawer: 12480,
              open: true,
            ),
          ),
          StaggerIn(
            index: 1,
            dy: 8,
            child: _RegisterCard(
              name: 'Register 2 · Kazanchis',
              status: 'Closed yesterday · counted & signed off',
              drawer: 0,
              open: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.name,
    required this.status,
    required this.drawer,
    required this.open,
  });

  final String name;
  final String status;
  final double drawer;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        border: Border.all(
            color: open
                ? pal.amber.withValues(alpha: 0.4)
                : pal.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.point_of_sale,
              size: 19, color: open ? pal.amber : pal.sage),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: pal.ink)),
                Text(status,
                    style: TextStyle(
                        fontSize: 11, color: pal.muted)),
                if (drawer > 0) ...<Widget>[
                  const SizedBox(height: 4),
                  Text('Drawer ${money(drawer)}',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: pal.ink)),
                ],
              ],
            ),
          ),
          if (open)
            PressableScale(
              pressedScale: 0.94,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(34),
                  backgroundColor: pal.ink,
                  foregroundColor: pal.toastText,
                ),
                onPressed: () => showSnack(
                    context, 'Register close flow is demo-only'),
                child: const Text('Close'),
              ),
            ),
        ],
      ),
    );
  }
}

class CatalogUpdatesScreen extends StatelessWidget {
  const CatalogUpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    return Scaffold(
      appBar: AppBar(title: const Text('Catalog & pricing')),
      body: _OpsList(items: store.catalogUpdates, actionLabel: 'Review'),
    );
  }
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: _OpsList(items: store.alerts, actionLabel: 'Mark read'),
    );
  }
}

class OfflineSyncScreen extends StatelessWidget {
  const OfflineSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    return Scaffold(
      appBar: AppBar(title: const Text('Offline sync')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: StaggerIn(
              index: 0,
              dy: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: pal(context).sage.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppTheme.rMd),
                  border: Border.all(
                      color:
                          pal(context).sage.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.cloud_sync_outlined,
                        size: 16, color: pal(context).sage),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          '${store.offlineQueue.length} items queued · last sync ${store.syncedLabel}',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: pal(context).ink)),
                    ),
                    PressableScale(
                      onTap: () {
                        store.syncNow();
                        showSnack(context, 'Sync complete');
                      },
                      pressedScale: 0.92,
                      child: Text('Sync now',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: pal(context).accent)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _OpsList(items: store.offlineQueue, padded: false),
          ),
        ],
      ),
    );
  }

  static Pal pal(BuildContext context) => Pal.of(context);
}

/// Generic row list used by the ops screens.
class _OpsList extends StatelessWidget {
  const _OpsList({
    required this.items,
    this.actionLabel,
    this.live = false,
    this.padded = true,
  });

  final List<OpsItem> items;
  final String? actionLabel;
  final bool live;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return ListView.separated(
      padding: EdgeInsets.all(padded ? 12 : 0),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int i) {
        final OpsItem item = items[i];
        return StaggerIn(
          index: i,
          child: Container(
            margin: EdgeInsets.only(bottom: padded ? 0 : 8, top: padded ? 0 : 0),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: pal.surface,
              borderRadius: BorderRadius.circular(AppTheme.rMd),
              border: Border.all(color: pal.border),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: pal.surfaceAlt,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(item.icon, size: 15, color: pal.ink),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(item.title,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: pal.ink)),
                      Text(item.subtitle,
                          style: TextStyle(
                              fontSize: 11, color: pal.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (actionLabel != null)
                  GestureDetector(
                    onTap: () =>
                        showSnack(context, '${item.title} · done'),
                    child: Text(actionLabel!,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: pal.accent)),
                  )
                else
                  Text(item.meta,
                      style: TextStyle(
                          fontSize: 10,
                          color: live
                              ? pal.sage
                              : pal.muted)),
              ],
            ),
          ),
        );
      },
    );
  }
}
