import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/store.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// App-bar bell — opens the notification feed and shows the unread
/// count badge when the signed-in role has fresh items.
class NotificationsBell extends StatelessWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final int unread = store.unreadNotificationCount;

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        IconButton(
          tooltip: 'Notifications',
          icon: Icon(unread > 0
              ? Icons.notifications_active_outlined
              : Icons.notifications_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (_) => const NotificationsScreen()),
          ),
        ),
        if (unread > 0)
          Positioned(
            top: 8,
            right: 8,
            child: BumpOnChange(
              trigger: unread,
              amount: 0.3,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 16),
                height: 16,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: pal.accent, shape: BoxShape.circle),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: TextStyle(
                      color: pal.toastText,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Feed of approval decisions (for sellers) and new submissions (for
/// managers), plus the register note that lands after a Z close.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final List<AppNotification> items = store.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: <Widget>[
          if (items.isNotEmpty) ...<Widget>[
            TextButton(
              onPressed: store.markAllNotificationsRead,
              child: const Text('Mark read'),
            ),
            IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              onPressed: store.clearNotifications,
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'All caught up',
              subtitle: 'Approval updates and register notes land here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              itemCount: items.length,
              itemBuilder: (BuildContext context, int i) {
                final AppNotification n = items[i];
                return StaggerIn(
                  index: i,
                  dy: 8,
                  child: _NotificationCard(
                    notification: n,
                    onTap: () => store.markNotificationRead(n.id),
                  ),
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    final AppNotification n = notification;

    final Color tone = switch (n.kind) {
      'approved' => pal.sage,
      'rejected' => pal.danger,
      'submit' => pal.amber,
      _ => pal.accent,
    };

    return PressableScale(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: n.read
              ? pal.surface
              : pal.softAccent.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppTheme.rMd),
          border: Border.all(
              color: n.read ? pal.border : tone.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(n.icon, size: 17, color: tone),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(n.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: pal.ink)),
                      ),
                      if (!n.read)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                              color: tone, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(n.body,
                      style: TextStyle(
                          fontSize: 12, height: 1.35, color: pal.muted)),
                  const SizedBox(height: 5),
                  Text('${shortDate(n.time)} · ${clockLabel(n.time)}',
                      style:
                          TextStyle(fontSize: 10.5, color: pal.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
