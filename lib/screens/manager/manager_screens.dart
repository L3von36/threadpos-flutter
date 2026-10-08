import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

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
