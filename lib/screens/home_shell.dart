import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'add/add_product_screen.dart';
import 'sales/sales_screen.dart';
import 'scan/scan_screen.dart';
import 'sell/sell_screen.dart';
import 'stock/stock_screen.dart';

/// Role-aware shell with the five-tab bottom navigation:
/// Sell · Scan · Add · Stock · Sales.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = <Widget>[
      const SellScreen(),
      ScanScreen(active: _index == 1),
      const AddProductScreen(),
      const StockScreen(),
      const SalesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: AppTheme.terracotta.withValues(alpha: 0.12),
        destinations: const <Widget>[
          NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Sell'),
          NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_outlined),
              selectedIcon: Icon(Icons.qr_code_scanner),
              label: 'Scan'),
          NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'Add'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Stock'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Sales'),
        ],
      ),
    );
  }
}
