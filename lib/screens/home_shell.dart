import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/store.dart';
import '../theme/app_theme.dart';
import 'add/add_product_screen.dart';
import 'sales/sales_screen.dart';
import 'scan/scan_screen.dart';
import 'sell/sell_screen.dart';
import 'stock/stock_screen.dart';

/// Role-aware shell with a compact five-tab bottom bar in the
/// WhatsApp / Instagram school: 54dp tall, hairline divider, 22dp
/// icons that swap outline→filled, small labels and a cart badge.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

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
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: _BottomBar(
        index: _index,
        cartCount: store.cartCount,
        onChanged: (int i) => setState(() => _index = i),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _BottomItem(
                    spec: _tabs[i],
                    selected: i == index,
                    badge: i == 0 && cartCount > 0 ? cartCount : null,
                    onTap: () => onChanged(i),
                  ),
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
    required this.onTap,
    this.badge,
  });

  final ({IconData rest, IconData active, String label}) spec;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final Color tint =
        selected ? AppTheme.terracotta : AppTheme.muted;
    return InkResponse(
      onTap: onTap,
      radius: 30,
      containedInkWell: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Icon(
                selected ? spec.active : spec.rest,
                size: 22,
                color: tint,
              ),
              if (badge != null)
                Positioned(
                  top: -5,
                  right: -9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3.5),
                    constraints: const BoxConstraints(minWidth: 14),
                    height: 14,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text(
                      badge! > 9 ? '9+' : '$badge',
                      style: const TextStyle(
                        fontSize: 8.5,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2.5),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
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
