import 'motion.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/store.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'account_sheet.dart';

/// Professional navigation drawer for Sami POS / ThreadPOS.
/// Displays workspace switcher, role indicator, navigation links to all modules,
/// quick Hive sync status, and sign out options.
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Header / Profile info
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: pal.border, width: 0.8)),
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: pal.accent.withValues(alpha: 0.15),
                    child: Text(
                      store.email.isNotEmpty ? store.email[0].toUpperCase() : 'S',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: pal.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          store.email.isNotEmpty ? store.email : 'Sami POS User',
                          style: TextStyle(
                            fontSize: 14.5,
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
                    selected: store.currentNavScreen == AppNavScreen.sales,
                    onTap: () {
                      Navigator.pop(context);
                      store.resetToNavScreen(AppNavScreen.sales);
                    },
                  ),
                  if (!store.isManager) ...<Widget>[
                    ListTile(
                      leading: Icon(Icons.storefront_outlined, color: pal.accent),
                      title: Text('Register & Sell',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: pal.ink)),
                      selected: store.currentNavScreen == AppNavScreen.sell,
                      onTap: () {
                        Navigator.pop(context);
                        store.resetToNavScreen(AppNavScreen.sell);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.qr_code_scanner_outlined, color: pal.accent),
                      title: Text('Barcode Scanner',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: pal.ink)),
                      selected: store.currentNavScreen == AppNavScreen.scan,
                      onTap: () {
                        Navigator.pop(context);
                        store.resetToNavScreen(AppNavScreen.scan);
                      },
                    ),
                  ],
                  ListTile(
                    leading: Icon(Icons.add_circle_outline, color: pal.accent),
                    title: Text('Add Clothing',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: pal.ink)),
                    selected: store.currentNavScreen == AppNavScreen.add,
                    onTap: () {
                      Navigator.pop(context);
                      store.resetToNavScreen(AppNavScreen.add);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.inventory_2_outlined, color: pal.accent),
                    title: Text('Stock & Inventory',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: pal.ink)),
                    selected: store.currentNavScreen == AppNavScreen.stock,
                    onTap: () {
                      Navigator.pop(context);
                      store.resetToNavScreen(AppNavScreen.stock);
                    },
                  ),
                  const Divider(height: 16),
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
                    selected: store.currentNavScreen == AppNavScreen.notifications,
                    onTap: () {
                      Navigator.pop(context);
                      store.navigateTo(AppNavScreen.notifications);
                    },
                  ),
                  if (store.isManager) ...<Widget>[
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
                      selected: store.currentNavScreen == AppNavScreen.analytics,
                      onTap: () {
                        Navigator.pop(context);
                        store.navigateTo(AppNavScreen.analytics);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.store_outlined, color: pal.accent),
                      title: Text('Store Branches',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: pal.ink)),
                      selected: store.currentNavScreen == AppNavScreen.branches,
                      onTap: () {
                        Navigator.pop(context);
                        store.navigateTo(AppNavScreen.branches);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.badge_outlined, color: pal.accent),
                      title: Text('Staff & Employees',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: pal.ink)),
                      selected: store.currentNavScreen == AppNavScreen.employees,
                      onTap: () {
                        Navigator.pop(context);
                        store.navigateTo(AppNavScreen.employees);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.payments_outlined, color: pal.accent),
                      title: Text('Financial Tracker',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: pal.ink)),
                      selected: store.currentNavScreen == AppNavScreen.finance,
                      onTap: () {
                        Navigator.pop(context);
                        store.navigateTo(AppNavScreen.finance);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.receipt_long_outlined, color: pal.accent),
                      title: Text('End of Day Reports',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: pal.ink)),
                      selected: store.currentNavScreen == AppNavScreen.reports,
                      onTap: () {
                        Navigator.pop(context);
                        store.navigateTo(AppNavScreen.reports);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.verified_outlined, color: pal.accent),
                      title: Text('Product Approvals',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: pal.ink)),
                      trailing: store.pendingProductCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: pal.warning,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${store.pendingProductCount}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                      selected: store.currentNavScreen == AppNavScreen.approvals,
                      onTap: () {
                        Navigator.pop(context);
                        store.navigateTo(AppNavScreen.approvals);
                      },
                    ),
                  ],
                  ListTile(
                    leading: Icon(Icons.cloud_sync_outlined, color: pal.accent),
                    title: Text('Offline Sync Queue',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: pal.ink)),
                    trailing: store.pendingOfflineCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: pal.warning,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${store.pendingOfflineCount}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    selected: store.currentNavScreen == AppNavScreen.offlineSync,
                    onTap: () {
                      Navigator.pop(context);
                      store.navigateTo(AppNavScreen.offlineSync);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.settings_outlined, color: pal.accent),
                    title: Text('Settings',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: pal.ink)),
                    selected: store.currentNavScreen == AppNavScreen.settings,
                    onTap: () {
                      Navigator.pop(context);
                      store.navigateTo(AppNavScreen.settings);
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
                store.navigateTo(AppNavScreen.offlineSync);
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
