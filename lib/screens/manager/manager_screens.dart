import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

// ---------------------------------------------------------------------------
// Employees
// ---------------------------------------------------------------------------

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: store.employees.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int i) {
          final Employee e = store.employees[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.terracotta
                      .withValues(alpha: 0.12),
                  child: Text(e.initial.toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.terracotta)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(e.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: AppTheme.ink)),
                      Text('${e.title} · ${e.branch}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.muted)),
                      const SizedBox(height: 4),
                      Text(e.shift,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.muted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(money(e.todaySales),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppTheme.ink)),
                    Text('comm. ${money(e.commission)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.sage)),
                  ],
                ),
              ],
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
    return Scaffold(
      appBar: AppBar(title: const Text('Branches')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: store.branches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int i) {
          final Branch b = store.branches[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(b.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: AppTheme.ink)),
                    ),
                    StockBadge(
                        label: '${b.staff} staff',
                        color: AppTheme.sage),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Manager · ${b.manager}',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppTheme.muted)),
                const SizedBox(height: 12),
                ProgressBar(value: b.progress, height: 9),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(money(b.revenue),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppTheme.terracotta)),
                    Text('target ${money(b.target)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.muted)),
                  ],
                ),
              ],
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
    final int today = DateTime.now().weekday;

    return Scaffold(
      appBar: AppBar(title: const Text('Scheduling')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          for (int day = 1; day <= 7; day++)
            if (store.schedule.any((ShiftSlot s) => s.day == day)) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: Row(
                  children: <Widget>[
                    Text(_dayNames[day],
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: day == today
                                ? AppTheme.terracotta
                                : AppTheme.ink)),
                    if (day == today) ...<Widget>[
                      const SizedBox(width: 8),
                      StockBadge(
                          label: 'Today', color: AppTheme.terracotta),
                    ],
                  ],
                ),
              ),
              ...store.schedule
                  .where((ShiftSlot s) => s.day == day)
                  .map((ShiftSlot s) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.access_time,
                                size: 16, color: AppTheme.muted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(s.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: AppTheme.ink)),
                            ),
                            Text(s.time,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.muted)),
                          ],
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
    final List<Employee> ranked = <Employee>[...store.employees]
      ..sort((Employee a, Employee b) => b.todaySales.compareTo(a.todaySales));
    final double maxSales =
        ranked.isEmpty ? 1 : ranked.first.todaySales;

    return Scaffold(
      appBar: AppBar(title: const Text('Performance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.creamDeep.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.emoji_events_outlined,
                    size: 20, color: AppTheme.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Commission rate 3% · daily target ${money(Store.shiftTarget)}',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < ranked.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == 0 ? AppTheme.amber : AppTheme.creamDeep,
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: i == 0
                                ? Colors.white
                                : AppTheme.ink)),
                  ),
                  const SizedBox(width: 12),
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: AppTheme.ink)),
                            ),
                            Text(money(ranked[i].todaySales),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                    color: AppTheme.terracotta)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ProgressBar(
                            value: maxSales <= 0
                                ? 0
                                : ranked[i].todaySales / maxSales,
                            height: 6),
                      ],
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
