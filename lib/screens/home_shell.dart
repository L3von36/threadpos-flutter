import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/store.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/motion.dart';
import 'add/add_product_screen.dart';
import 'sales/sales_screen.dart';
import 'scan/scan_screen.dart';
import 'sell/cart_screen.dart';
import 'sell/sell_screen.dart';
import 'stock/stock_screen.dart';

/// Role-aware shell with a compact bottom bar in the WhatsApp /
/// Instagram school: 56dp tall, hairline divider, 22dp icons that swap
/// outline->filled with a springy bounce, a soft sliding pill behind
/// the active tab and a cart-count badge.
///
/// Sellers get the full five-tab floor experience; managers work from
/// the Add / Stock / Sales trio like the reference design. A floating
/// cart pill slides in on any tab where the current sale isn't
/// reachable from the tab bar itself.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  /// Replays a quick fade-through every time the active tab changes.
  late final AnimationController _tabFade = AnimationController(
    vsync: this,
    duration: Motion.base,
    value: 1, // no entrance animation on first build
  );

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _tabFade.forward(from: 0);
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _tabFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final bool manager = store.isManager;

    final List<Widget> tabs = manager
        ? <Widget>[
            const AddProductScreen(),
            const StockScreen(),
            const SalesScreen(),
          ]
        : <Widget>[
            const SellScreen(),
            ScanScreen(active: _index == 1),
            const AddProductScreen(),
            const StockScreen(),
            const SalesScreen(),
          ];

    // Role switches can shrink the tab list — keep the index in range
    // so the IndexedStack and the pill never point past the end.
    final int idx = _index.clamp(0, tabs.length - 1);
    final bool sellTabVisible = !manager && idx == 0;

    // The floating pill is the cart entry point everywhere the tab bar
    // doesn't already badge it (i.e. everywhere except the Sell tab).
    final bool showCartPill =
        store.cartCount > 0 && !(sellTabVisible);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          AnimatedBuilder(
            animation: _tabFade,
            builder: (BuildContext context, Widget? child) {
              final double t = Motion.out.transform(_tabFade.value);
              return Opacity(
                opacity: t < 0 ? 0 : (t > 1 ? 1 : t),
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 7),
                  child: child,
                ),
              );
            },
            child: IndexedStack(index: idx, children: tabs),
          ),
          // Floating "view current sale" pill.
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 10),
                      decoration: BoxDecoration(
                        color: pal(context).bannerBg,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.24),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: <Widget>[
                          BumpOnChange(
                            trigger: store.cartCount,
                            child: Badge(
                              backgroundColor: pal(context).accent,
                              label: Text('${store.cartCount}',
                                  style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                      color: Colors.white)),
                              child: Icon(Icons.shopping_bag_outlined,
                                  size: 17,
                                  color: pal(context).bannerText),
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
      bottomNavigationBar: _BottomBar(
        index: idx,
        manager: manager,
        cartCount: store.cartCount,
        onChanged: _select,
      ),
    );
  }

  static Pal pal(BuildContext context) => Pal.of(context);
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.spec,
    required this.selected,
    required this.badgeVisible,
    required this.onTap,
    this.badge,
  });

  final ({IconData rest, IconData active, String label}) spec;
  final bool selected;
  final bool badgeVisible;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    final Color tint = selected ? pal.accent : pal.muted;
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.88,
      hoverScale: 1.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              // Icon swaps outline -> filled with a springy pop.
              AnimatedSwitcher(
                duration: Motion.fast,
                switchInCurve: Motion.pop,
                switchOutCurve: Motion.out,
                transitionBuilder: (Widget child, Animation<double> anim) =>
                    ScaleTransition(
                  scale: Tween<double>(begin: 0.72, end: 1).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  selected ? spec.active : spec.rest,
                  key: ValueKey<bool>(selected),
                  size: 22,
                  color: tint,
                ),
              ),
              if (badge != null)
                Positioned(
                  top: -5,
                  right: -9,
                  child: AnimatedOpacity(
                    duration: Motion.fast,
                    opacity: badgeVisible ? 1 : 0,
                    child: BumpOnChange(
                      trigger: badge!,
                      amount: 0.3,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 3.5),
                        constraints: const BoxConstraints(minWidth: 14),
                        height: 14,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: pal.accent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: pal.surface, width: 1),
                        ),
                        child: Text(
                          badge! > 9 ? '9+' : '$badge',
                          style: TextStyle(
                            fontSize: 8.5,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            color: pal.toastText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2.5),
          AnimatedDefaultTextStyle(
            duration: Motion.fast,
            curve: Curves.easeOut,
            style: TextStyle(
              fontSize: 10.5,
              height: 1,
              letterSpacing: 0.1,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: tint,
            ),
            child: Text(spec.label),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
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
    (rest: Icons.storefront_outlined, active: Icons.storefront, label: 'Sell'),
    (rest: Icons.qr_code_scanner_outlined,
        active: Icons.qr_code_scanner,
        label: 'Scan'),
    (rest: Icons.add_circle_outline, active: Icons.add_circle, label: 'Add'),
    (rest: Icons.inventory_2_outlined,
        active: Icons.inventory_2,
        label: 'Stock'),
    (rest: Icons.bar_chart_outlined, active: Icons.bar_chart, label: 'Sales'),
  ];

  static const List<({IconData rest, IconData active, String label})>
      _managerTabs = <({IconData rest, IconData active, String label})>[
    (rest: Icons.add_circle_outline, active: Icons.add_circle, label: 'Add'),
    (rest: Icons.inventory_2_outlined,
        active: Icons.inventory_2,
        label: 'Stock'),
    (rest: Icons.bar_chart_outlined, active: Icons.bar_chart, label: 'Sales'),
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
              // Soft pill that glides behind the active tab.
              Positioned.fill(
                child: AnimatedAlign(
                  duration: Motion.base,
                  curve: Motion.out,
                  // Works for any tab count: -1 .. 1 across the row.
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
                      child: _BottomItem(
                        spec: tabs[i],
                        selected: i == index,
                        badge: i == 0 && cartCount > 0 ? cartCount : null,
                        badgeVisible: i == 0 && cartCount > 0,
                        onTap: () => onChanged(i),
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
