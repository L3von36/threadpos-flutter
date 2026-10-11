import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../screens/notifications_screen.dart';
import '../state/store.dart';
import 'account_sheet.dart';
import 'offline_badge.dart';

/// Unified top navigation bar across every screen in Sami POS / ThreadPOS.
/// Provides an identical structure, actions, and drawer controls across all views:
/// - Drawer hamburger icon (or back button if on a secondary screen)
/// - Screen title
/// - Optional screen-specific actions
/// - OfflineStatusChip
/// - NotificationsBell
/// - Settings shortcut
/// - Theme mode toggle (Light / Dark)
/// - Workspace & profile account switcher
class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({
    super.key,
    required this.title,
    this.extraActions,
    this.showBackButton,
    this.onBack,
  });

  final String title;
  final List<Widget>? extraActions;
  final bool? showBackButton;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasBack = showBackButton ?? store.canPopNavScreen;

    return AppBar(
      leading: hasBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 21),
              tooltip: 'Back',
              onPressed: () {
                if (onBack != null) {
                  onBack!();
                } else if (store.canPopNavScreen) {
                  store.popNavScreen();
                } else {
                  Navigator.maybePop(context);
                }
              },
            )
          : IconButton(
              icon: const Icon(Icons.menu_rounded, size: 22),
              tooltip: 'Open navigation drawer',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
      title: Text(title),
      actions: <Widget>[
        if (extraActions != null) ...extraActions!,
        const OfflineStatusChip(),
        const NotificationsBell(),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_outlined, size: 20),
          onPressed: () => store.navigateTo(AppNavScreen.settings),
        ),
        IconButton(
          tooltip: 'Toggle light / dark mode',
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 20,
          ),
          onPressed: () {
            store.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
          },
        ),
        IconButton(
          tooltip: 'Workspace & sign out',
          icon: const Icon(Icons.switch_account_outlined, size: 20),
          onPressed: () => showAccountSheet(context),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}
