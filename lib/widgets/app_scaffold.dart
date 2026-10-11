import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/store.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../screens/sell/cart_screen.dart';
import 'app_drawer.dart';
import 'app_nav_bar.dart';
import 'motion.dart';

/// Reusable global AppScaffold that encapsulates the shared Drawer, AppNavBar,
/// BottomNavigationBar, and floating UI elements (offline banner & cart pill),
/// allowing individual pages to only define their unique body content.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.extraActions,
    this.showBottomBar = true,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? extraActions;
  final bool showBottomBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final bool manager = store.isManager;
    final AppNavScreen current = store.currentNavScreen;
    final int tabIndex = _currentIndexFor(current, manager);
    final bool shouldShowBottomBar = showBottomBar && tabIndex >= 0;
    final bool sellTabVisible = !manager && current == AppNavScreen.sell;
    final bool showCartPill = store.cartCount > 0 && !sellTabVisible;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(
        title: title,
        extraActions: extraActions,
      ),
      body: Stack(
        children: <Widget>[
          body,
          // Floating offline banner when offline
          if (store.isOffline)
            Positioned(
              top: 4,
              left: 14,
              right: 14,
              child: StaggerIn(
                index: 0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.rMd),
                    onTap: () => store.navigateTo(AppNavScreen.offlineSync),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                      decoration: BoxDecoration(
                        color: pal(context).warning.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(AppTheme.rMd),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.wifi_off_rounded, size: 15, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              store.pendingOfflineCount == 0
                                  ? 'Offline · Hive local storage active'
                                  : 'Offline · ${store.pendingOfflineCount} queued for auto-sync',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Offline',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Floating cart pill
          Positioned(
            left: 14,
            right: 14,
            bottom: 10,
            child: IgnorePointer(
              ignoring: !showCartPill,
              child: AnimatedSlide(
                duration: Motion.base,
                curve: Motion.out,
                offset: showCartPill ? Offset.zero : const Offset(0, 1.4),
                child: AnimatedOpacity(
                  duration: Motion.fast,
                  opacity: showCartPill ? 1 : 0,
                  child: PressableScale(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const CartScreen()),
                    ),
                    pressedScale: 0.97,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: pal(context).bannerBg,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: pal(context).accent.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: pal(context).bannerText.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: BumpOnChange(
                              trigger: store.cartCount,
                              amount: 0.4,
                              child: Text(
                                '${store.cartCount}',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'View sale · ${money(store.cartTotal)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: pal(context).bannerText),
                            ),
                          ),
                          Icon(Icons.arrow_forward_rounded,
                              size: 16, color: pal(context).bannerSub),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: shouldShowBottomBar
          ? _AppBottomBar(
              index: tabIndex,
              manager: manager,
              cartCount: store.cartCount,
              onChanged: (int i) => _onTabChanged(context, i, manager),
            )
          : null,
    );
  }

  int _currentIndexFor(AppNavScreen screen, bool manager) {
    if (manager) {
      switch (screen) {
        case AppNavScreen.sales:
          return 0;
        case AppNavScreen.add:
          return 1;
        case AppNavScreen.stock:
          return 2;
        default:
          return -1;
      }
    } else {
      switch (screen) {
        case AppNavScreen.sales:
          return 0;
        case AppNavScreen.sell:
          return 1;
        case AppNavScreen.scan:
          return 2;
        case AppNavScreen.add:
          return 3;
        case AppNavScreen.stock:
          return 4;
        default:
          return -1;
      }
    }
  }

  void _onTabChanged(BuildContext context, int index, bool manager) {
    final Store store = context.read<Store>();
    if (manager) {
      switch (index) {
        case 0:
          store.resetToNavScreen(AppNavScreen.sales);
          break;
        case 1:
          store.resetToNavScreen(AppNavScreen.add);
          break;
        case 2:
          store.resetToNavScreen(AppNavScreen.stock);
          break;
      }
    } else {
      switch (index) {
        case 0:
          store.resetToNavScreen(AppNavScreen.sales);
          break;
        case 1:
          store.resetToNavScreen(AppNavScreen.sell);
          break;
        case 2:
          store.resetToNavScreen(AppNavScreen.scan);
          break;
        case 3:
          store.resetToNavScreen(AppNavScreen.add);
          break;
        case 4:
          store.resetToNavScreen(AppNavScreen.stock);
          break;
      }
    }
  }

  static Pal pal(BuildContext context) => Pal.of(context);
}

class _AppBottomBar extends StatelessWidget {
  const _AppBottomBar({
    required this.index,
    required this.manager,
    required this.cartCount,
    required this.onChanged,
  });

  final int index;
  final bool manager;
  final int cartCount;
  final ValueChanged<int> onChanged;

  static const List<({IconData rest, IconData active, String label})>
      _sellerTabs = <({IconData rest, IconData active, String label})>[
    (rest: Icons.bar_chart_outlined, active: Icons.bar_chart, label: 'Sales'),
    (rest: Icons.storefront_outlined, active: Icons.storefront, label: 'Sell'),
    (rest: Icons.qr_code_scanner_outlined,
        active: Icons.qr_code_scanner,
        label: 'Scan'),
    (rest: Icons.add_circle_outline, active: Icons.add_circle, label: 'Add'),
    (rest: Icons.inventory_2_outlined,
        active: Icons.inventory_2,
        label: 'Stock'),
  ];

  static const List<({IconData rest, IconData active, String label})>
      _managerTabs = <({IconData rest, IconData active, String label})>[
    (rest: Icons.bar_chart_outlined, active: Icons.bar_chart, label: 'Sales'),
    (rest: Icons.add_circle_outline, active: Icons.add_circle, label: 'Add'),
    (rest: Icons.inventory_2_outlined,
        active: Icons.inventory_2,
        label: 'Stock'),
  ];

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    final List<({IconData rest, IconData active, String label})> tabs =
        manager ? _managerTabs : _sellerTabs;
    return Container(
      decoration: BoxDecoration(
        color: pal.surface,
        border: Border(top: BorderSide(color: pal.border, width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: AnimatedAlign(
                  duration: Motion.base,
                  curve: Motion.out,
                  alignment: Alignment(-1 + 2 * index / (tabs.length - 1), 0),
                  child: FractionallySizedBox(
                    widthFactor: 1 / tabs.length,
                    heightFactor: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: pal.softAccent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  for (int i = 0; i < tabs.length; i++)
                    Expanded(
                      child: PressableScale(
                        onTap: () => onChanged(i),
                        pressedScale: 0.88,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              i == index ? tabs[i].active : tabs[i].rest,
                              size: 22,
                              color: i == index ? pal.accent : pal.muted,
                            ),
                            const SizedBox(height: 2.5),
                            Text(
                              tabs[i].label,
                              style: TextStyle(
                                fontSize: 10.5,
                                height: 1,
                                fontWeight: i == index
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: i == index ? pal.accent : pal.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
