import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/store.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../screens/settings_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/manager/visual_analytics_screen.dart';
import '../widgets/account_sheet.dart';
import '../widgets/motion.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: pal.surface,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: pal.surfaceAlt.withValues(alpha: 0.6),
                border: Border(bottom: BorderSide(color: pal.border, width: 0.8)),
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: pal.accent.withValues(alpha: 0.15),
                    child: Text(
                      store.displayName.isEmpty
                          ? '?'
                          : store.displayName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: pal.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          store.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: pal.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: pal.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            store.isManager ? 'Manager Workspace' : 'Seller Workspace',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: pal.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.dashboard_outlined, color: pal.accent),
                    title: Text('Dashboard',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: pal.ink)),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.notifications_outlined, color: pal.accent),
                    title: Text('Notifications',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: pal.ink)),
                    trailing: store.unreadNotificationCount > 0
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: pal.danger,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${store.unreadNotificationCount}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (store.isManager)
                    ListTile(
                      leading:
                          Icon(Icons.bar_chart_rounded, color: pal.accent),
                      title: Text('Visual Analytics',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: pal.ink)),
                      subtitle: Text('Revenue & top item bar charts',
                          style:
                              TextStyle(fontSize: 11, color: pal.muted)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const VisualAnalyticsScreen(),
                          ),
                        );
                      },
                    ),
                  ListTile(
                    leading: Icon(Icons.settings_outlined, color: pal.accent),
                    title: Text('Settings',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: pal.ink)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: pal.accent,
                    ),
                    title: Text(
                      isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: pal.ink),
                    ),
                    onTap: () {
                      store.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
                    },
                  ),
                  const Divider(height: 24),
                  ListTile(
                    leading: Icon(Icons.switch_account_outlined, color: pal.accent),
                    title: Text('Switch Workspace / Role',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: pal.ink)),
                    onTap: () {
                      Navigator.pop(context);
                      showAccountSheet(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.point_of_sale_outlined, color: pal.accent),
                    title: Text('Cash Drawer Status',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: pal.ink)),
                    subtitle: Text('Active shift float: ${money(12480)}',
                        style: TextStyle(fontSize: 11, color: pal.muted)),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cash Drawer active with 12,480 ETB float')),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Network / Hive Sync Status Banner
            InkWell(
              onTap: () {
                Navigator.pop(context);
                showOfflineSheet(context, store);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: (store.isOffline ? pal.warning : pal.sage)
                    .withValues(alpha: 0.1),
                border: Border(top: BorderSide(color: pal.border, width: 0.8)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    store.isOffline
                        ? Icons.cloud_off_rounded
                        : Icons.cloud_done_rounded,
                    size: 16,
                    color: store.isOffline ? pal.warning : pal.sage,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      store.isOffline
                          ? 'Offline · ${store.pendingOfflineCount} queued'
                          : 'Online · Synced ${store.syncedLabel}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: store.isOffline ? pal.warning : pal.sage,
                      ),
                    ),
                  ),
                  if (store.pendingOfflineCount > 0)
                    PressableScale(
                      onTap: () {
                        store.syncNow();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Syncing offline transactions...')),
                        );
                      },
                      child: Text(
                        'Sync',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: pal.accent,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: pal.muted,
                  ),
                ],
              ),
            ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: pal.border, width: 0.8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('POS Enterprise v1.0',
                      style: TextStyle(fontSize: 11, color: pal.muted)),
                  IconButton(
                    icon: Icon(Icons.logout_rounded, size: 20, color: pal.danger),
                    tooltip: 'Sign out',
                    onPressed: () {
                      Navigator.pop(context);
                      showAccountSheet(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
