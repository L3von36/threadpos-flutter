import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/store.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _targetController;
  late final TextEditingController _commissionController;

  @override
  void initState() {
    super.initState();
    final Store store = context.read<Store>();
    _targetController =
        TextEditingController(text: store.dailyTarget.round().toString());
    _commissionController =
        TextEditingController(text: store.commissionRate.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _targetController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool manager = store.isManager;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // Section: Appearance
          Text('Appearance & Theme',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: pal.muted,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: pal.surfaceAlt.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.rMd),
            ),
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  title: Text('Dark Mode',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: pal.ink)),
                  subtitle: Text(
                      isDark ? 'Currently using dark theme' : 'Currently using light theme',
                      style: TextStyle(fontSize: 12, color: pal.muted)),
                  value: isDark,
                  onChanged: (bool val) {
                    store.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Business & Targets
          Text('Business & Targets',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: pal.muted,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: pal.surfaceAlt.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.rMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Daily Team Target (ETB)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: pal.ink)),
                const SizedBox(height: 6),
                TextField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g. 50000',
                    filled: true,
                    fillColor: pal.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.rSm),
                      borderSide: BorderSide(color: pal.border),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Commission Rate (%)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: pal.ink)),
                const SizedBox(height: 6),
                TextField(
                  controller: _commissionController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g. 3',
                    filled: true,
                    fillColor: pal.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.rSm),
                      borderSide: BorderSide(color: pal.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pal.accent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final double? d = double.tryParse(_targetController.text);
                      final double? c = double.tryParse(_commissionController.text);
                      if (d != null) store.setDailyTarget(d);
                      if (c != null) store.setCommissionRate(c);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings saved successfully')),
                      );
                    },
                    child: const Text('Save Business Targets'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Cash Drawer & Notifications
          Text('Cash Drawer & Notifications',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: pal.muted,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: pal.surfaceAlt.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.rMd),
            ),
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.point_of_sale_outlined, color: pal.accent),
                  title: Text('Cash Drawer Status',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: pal.ink)),
                  subtitle: Text('Active shift open with floating float',
                      style: TextStyle(fontSize: 12, color: pal.muted)),
                  trailing: Text(money(12480),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: pal.sage)),
                ),
                Divider(height: 1, color: pal.border),
                ListTile(
                  leading: Icon(Icons.notifications_active_outlined, color: pal.accent),
                  title: Text('Low Stock Alerts',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: pal.ink)),
                  subtitle: Text('Alert when stock falls below threshold',
                      style: TextStyle(fontSize: 12, color: pal.muted)),
                  trailing: Switch(
                    value: true,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Workspace & Role
          Text('Workspace Role',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: pal.muted,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: pal.surfaceAlt.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.rMd),
            ),
            child: ListTile(
              leading: Icon(
                manager ? Icons.admin_panel_settings : Icons.person_outline,
                color: pal.accent,
              ),
              title: Text(
                manager ? 'Manager Workspace Active' : 'Seller Workspace Active',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: pal.ink),
              ),
              subtitle: Text(store.email.isEmpty ? 'Connected user' : store.email,
                  style: TextStyle(fontSize: 12, color: pal.muted)),
              trailing: TextButton(
                onPressed: () => store.switchRole(),
                child: Text('Switch Role',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: pal.accent)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section: Local Persistence & Offline Sync (Hive)
          Text('Local Persistence & Offline Sync (Hive)',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: pal.muted,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: pal.surfaceAlt.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.rMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          store.isOffline
                              ? Icons.cloud_off_rounded
                              : Icons.cloud_done_rounded,
                          size: 18,
                          color: store.isOffline ? pal.warning : pal.sage,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          store.isOffline
                              ? 'Internet Outage (Offline)'
                              : 'Network Connected (Online)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: store.isOffline ? pal.warning : pal.sage,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (store.isOffline ? pal.warning : pal.sage)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.rSm),
                      ),
                      child: Text(
                        'Hive DB Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: store.isOffline ? pal.warning : pal.sage,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Hive persists all product catalog, stock inventory, and sales transactions locally so checkout remains fully operational with zero network.',
                  style: TextStyle(fontSize: 12, color: pal.muted, height: 1.4),
                ),
                const Divider(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Simulate Internet Outage',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: pal.ink)),
                  subtitle: Text(
                      'Disables network connection to test offline POS sales & queueing',
                      style: TextStyle(fontSize: 11.5, color: pal.muted)),
                  value: store.isSimulatedOffline,
                  onChanged: (bool val) => store.setSimulatedOffline(val),
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Offline Queue Status',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: pal.ink)),
                        const SizedBox(height: 2),
                        Text(
                          store.pendingOfflineCount == 0
                              ? 'All transactions synced · Last ${store.syncedLabel}'
                              : '${store.pendingOfflineCount} transaction(s) pending sync',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: store.pendingOfflineCount > 0
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: store.pendingOfflineCount > 0
                                ? pal.warning
                                : pal.muted,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pal.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      onPressed: store.isSyncing
                          ? null
                          : () async {
                              final int synced = await store.syncNow();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(synced > 0
                                        ? 'Successfully synced $synced transaction(s) to cloud!'
                                        : 'All records are already up to date.'),
                                  ),
                                );
                              }
                            },
                      icon: store.isSyncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync, size: 16),
                      label: Text(store.isSyncing ? 'Syncing...' : 'Sync Now'),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _SysInfoRow(
                  label: 'Catalog In Local Hive',
                  value: '${store.cachedProductsCount} items cached',
                ),
                const SizedBox(height: 8),
                _SysInfoRow(
                  label: 'Total Sales In Hive Box',
                  value: '${store.cachedSalesCount} transactions',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: System Information
          Text('System Information',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: pal.muted,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: pal.surfaceAlt.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.rMd),
            ),
            child: Column(
              children: <Widget>[
                _SysInfoRow(label: 'App Version', value: 'v1.7.0 Enterprise'),
                const Divider(height: 16),
                _SysInfoRow(label: 'Local Storage Engine', value: 'Hive NoSQL v2.2.3'),
                const Divider(height: 16),
                _SysInfoRow(
                    label: 'Network / Sync Status',
                    value: store.isOffline
                        ? 'Offline Outage (${store.pendingOfflineCount} queued)'
                        : 'Online (Cloud Active)'),
                const Divider(height: 16),
                _SysInfoRow(
                    label: 'Session Status',
                    value: manager
                        ? 'Manager Privileges'
                        : 'Standard POS Access'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: pal.danger,
              side: BorderSide(color: pal.danger.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.rMd),
              ),
            ),
            onPressed: () {
              store.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/', (Route<dynamic> r) => false);
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Log Out',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text('POS Enterprise · Secure Management Suite',
                style: TextStyle(fontSize: 11, color: pal.muted)),
          ),
        ],
      ),
    );
  }
}

class _SysInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _SysInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: TextStyle(fontSize: 13, color: pal.muted)),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: pal.ink)),
      ],
    );
  }
}
