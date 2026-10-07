import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                      Text('comm. ${money(e.commission)}',
                          style: TextStyle(
                              fontSize: 10.5, color: pal.sage)),
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
