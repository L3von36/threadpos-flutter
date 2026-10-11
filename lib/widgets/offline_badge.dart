import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/manager/manager_screens.dart';
import '../state/store.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'motion.dart';

/// Interactive chip displayed in AppBars showing real-time connectivity status.
/// Tapping opens a quick connectivity sheet to toggle simulated offline outage
/// and inspect or trigger synchronization of pending transactions.
class OfflineStatusChip extends StatelessWidget {
  const OfflineStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final bool offline = store.isOffline;
    final int queued = store.pendingOfflineCount;

    return PressableScale(
      onTap: () => showOfflineSheet(context, store),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (offline ? pal.warning : pal.sage).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: (offline ? pal.warning : pal.sage).withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              offline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
              size: 13,
              color: offline ? pal.warning : pal.sage,
            ),
            const SizedBox(width: 5),
            Text(
              offline
                  ? (queued > 0 ? 'Offline ($queued)' : 'Offline')
                  : 'Online',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: offline ? pal.warning : pal.sage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a bottom sheet with connectivity status, offline outage simulation
/// toggle, and quick synchronization controls.
void showOfflineSheet(BuildContext context, Store store) {
  final Pal pal = Pal.of(context);
  showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext sheetCtx) {
      return Consumer<Store>(
        builder: (BuildContext _, Store s, Widget? __) {
          final bool offline = s.isOffline;
          final int queued = s.pendingOfflineCount;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        offline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                        color: offline ? pal.warning : pal.sage,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Offline Mode & Persistence',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: pal.ink,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (offline ? pal.warning : pal.sage).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.rMd),
                      border: Border.all(
                        color: (offline ? pal.warning : pal.sage).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          offline
                              ? 'Device Offline (Hive Local Engine Active)'
                              : 'Connected Online (All Stores Synced)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: offline ? pal.warning : pal.sage,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offline
                              ? 'Sales are stored in local Hive storage with zero data loss. $queued transaction(s) queued.'
                              : 'Hive database caches products and inventory. Last sync: ${s.syncedLabel}.',
                          style: TextStyle(fontSize: 11.5, color: pal.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Simulate Internet Outage',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: pal.ink,
                      ),
                    ),
                    subtitle: Text(
                      'Test offline POS checkout, receipt storage, and queueing',
                      style: TextStyle(fontSize: 11.5, color: pal.muted),
                    ),
                    value: s.isSimulatedOffline,
                    onChanged: (bool val) {
                      s.setSimulatedOffline(val);
                      showSnack(
                        sheetCtx,
                        val
                            ? 'Simulated Outage enabled: POS is now offline'
                            : 'Online mode restored: auto-syncing pending sales',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const OfflineSyncScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.list_alt_rounded, size: 16),
                          label: Text('View Queue ($queued)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: s.isSyncing
                              ? null
                              : () async {
                                  final int synced = await s.syncNow();
                                  if (sheetCtx.mounted) {
                                    showSnack(
                                      sheetCtx,
                                      synced > 0
                                          ? 'Successfully synced $synced transaction(s)'
                                          : 'All transactions already synced',
                                    );
                                  }
                                },
                          icon: s.isSyncing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync_rounded, size: 16),
                          label: Text(s.isSyncing ? 'Syncing...' : 'Sync Now'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
