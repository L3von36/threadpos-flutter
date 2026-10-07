import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/store.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';
import 'add/add_product_screen.dart';
import 'sales/sales_screen.dart';
import 'scan/scan_screen.dart';
import 'sell/sell_screen.dart';
import 'stock/stock_screen.dart';

/// Role-aware shell with a compact five-tab bottom bar in the
/// WhatsApp / Instagram school: 56dp tall, hairline divider, 22dp
/// icons that swap outline->filled with a springy bounce, a soft
/// sliding pill behind the active tab and a cart-count badge.
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
    final List<Widget> tabs = <Widget>[
      const SellScreen(),
      ScanScreen(active: _index == 1),
      const AddProductScreen(),
      const StockScreen(),
      const SalesScreen(),
    ];

    return Scaffold(
      body: AnimatedBuilder(
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
        child: IndexedStack(index: _index, children: tabs),
      ),
      bottomNavigationBar: _BottomBar(
        index: _index,
        cartCount: store.cartCount,
        onChanged: _select,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.cartCount,
    required this.onChanged,
  });

  final int index;
  final int cartCount;
  final ValueChanged<int> onChanged;

  static const List<({IconData rest, IconData active, String label})>
      _tabs = <({IconData rest, IconData active, String label})>[
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

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
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
                  alignment: Alignment(-1 + 0.5 * index, 0),
                  child: FractionallySizedBox(
                    widthFactor: 1 / _tabs.length,
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
                  for (int i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: _BottomItem(
                        spec: _tabs[i],
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
