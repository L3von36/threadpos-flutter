import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/store.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';

/// Workspace sheet opened from the Sell greeting avatar and the Sales
/// app bar: shows who is signed in and offers role switching, sign out
/// and the light/dark appearance toggle.
Future<void> showAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext sheetContext) =>
        ChangeNotifierProvider<Store>.value(
      value: sheetContext.read<Store>(),
      child: const _AccountSheet(),
    ),
  );
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool manager = store.isManager;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Workspace banner.
            StaggerIn(
              index: 0,
              dy: 10,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pal.bannerBg,
                  borderRadius: BorderRadius.circular(AppTheme.rLg),
                ),
                child: Row(
                  children: <Widget>[
                    PopIn(
                      begin: 0.6,
                      duration: Motion.base,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.14),
                        child: Text(
                          store.displayName.isEmpty
                              ? '?'
                              : store.displayName[0].toUpperCase(),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: pal.bannerText),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                              manager
                                  ? 'Manager workspace'
                                  : 'Seller workspace',
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: pal.bannerText)),
                          Text(
                            store.email.isEmpty
                                ? 'Signed in on this device'
                                : store.email,
                            style: TextStyle(
                                fontSize: 11, color: pal.bannerSub),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      manager ? Icons.insights : Icons.storefront,
                      size: 19,
                      color: pal.bannerText,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            StaggerIn(
              index: 1,
              dy: 8,
              child: _SheetAction(
                icon: Icons.switch_account_outlined,
                label: manager
                    ? 'Switch to Seller workspace'
                    : 'Switch to Manager workspace',
                sub: 'Keeps this device signed in',
                onTap: () {
                  Navigator.of(context).pop();
                  store.switchRole();
                },
              ),
            ),
            StaggerIn(
              index: 2,
              dy: 8,
              child: _SheetAction(
                icon: Icons.logout,
                label: 'Sign out',
                sub: 'Return to the sign-in screen',
                danger: true,
                onTap: () {
                  Navigator.of(context).pop();
                  store.logout();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/', (Route<dynamic> r) => false);
                },
              ),
            ),
            StaggerIn(
              index: 3,
              dy: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: pal.surface,
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                  border: Border.all(color: pal.border),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.brightness_6_outlined,
                        size: 18, color: pal.muted),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text('Appearance',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: pal.ink)),
                    ),
                    Text(
                      store.themeMode == ThemeMode.dark
                          ? 'Dark'
                          : (store.themeMode == ThemeMode.light
                              ? 'Light'
                              : 'System'),
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: pal.muted),
                    ),
                    ThemeToggle(
                      dark: isDark,
                      onToggle: () => store.setThemeMode(
                          isDark ? ThemeMode.light : ThemeMode.dark),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Private workspace · Store team access only',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: pal.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    final Color tint = danger ? pal.danger : pal.accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PressableScale(
        onTap: onTap,
        pressedScale: 0.97,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: pal.surface,
            borderRadius: BorderRadius.circular(AppTheme.rMd),
            border: Border.all(
                color: danger
                    ? pal.danger.withValues(alpha: 0.35)
                    : pal.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: tint),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: danger ? pal.danger : pal.ink)),
                    Text(sub,
                        style: TextStyle(
                            fontSize: 10.5, color: pal.muted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: pal.muted),
            ],
          ),
        ),
      ),
    );
  }
}
