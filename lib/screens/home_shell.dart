import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/store.dart';
import '../widgets/app_scaffold.dart';
import 'add/add_product_screen.dart';
import 'manager/approval_screens.dart';
import 'manager/branch_screens.dart';
import 'manager/employee_screens.dart';
import 'manager/finance_screens.dart';
import 'manager/manager_screens.dart';
import 'manager/report_screens.dart';
import 'manager/visual_analytics_screen.dart';
import 'notifications_screen.dart';
import 'sales/sales_screen.dart';
import 'scan/scan_screen.dart';
import 'sell/sell_screen.dart';
import 'settings_screen.dart';
import 'stock/stock_screen.dart';

/// Global HomeShell powered by Provider state management and AppScaffold.
/// Encapsulates the shared Drawer, AppNavBar, and BottomNavigationBar,
/// ensuring persistent UI layout components globally across all routes.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final bool manager = store.isManager;
    final AppNavScreen current = store.currentNavScreen;

    return AppScaffold(
      title: _titleFor(current, manager),
      body: _screenFor(current),
    );
  }

  String _titleFor(AppNavScreen screen, bool manager) {
    switch (screen) {
      case AppNavScreen.sales:
        return manager ? 'Manager Dashboard' : 'Sales overview';
      case AppNavScreen.sell:
        return 'Register & Sell';
      case AppNavScreen.scan:
        return 'Scan barcode';
      case AppNavScreen.add:
        return 'Add clothing';
      case AppNavScreen.stock:
        return manager ? 'Inventory control' : 'Stock';
      case AppNavScreen.notifications:
        return 'Notifications';
      case AppNavScreen.analytics:
        return 'Visual Analytics';
      case AppNavScreen.settings:
        return 'Settings';
      case AppNavScreen.offlineSync:
        return 'Offline Sync Queue';
      case AppNavScreen.branches:
        return 'Store Branches';
      case AppNavScreen.employees:
        return 'Staff & Employees';
      case AppNavScreen.finance:
        return 'Financial Tracker';
      case AppNavScreen.reports:
        return 'End of Day Reports';
      case AppNavScreen.approvals:
        return 'Product Approvals';
    }
  }

  Widget _screenFor(AppNavScreen screen) {
    switch (screen) {
      case AppNavScreen.sales:
        return const SalesScreen();
      case AppNavScreen.sell:
        return const SellScreen();
      case AppNavScreen.scan:
        return const ScanScreen(active: true);
      case AppNavScreen.add:
        return const AddProductScreen();
      case AppNavScreen.stock:
        return const StockScreen();
      case AppNavScreen.notifications:
        return const NotificationsScreen();
      case AppNavScreen.analytics:
        return const VisualAnalyticsScreen();
      case AppNavScreen.settings:
        return const SettingsScreen();
      case AppNavScreen.offlineSync:
        return const OfflineSyncScreen();
      case AppNavScreen.branches:
        return const BranchesScreen();
      case AppNavScreen.employees:
        return const EmployeesScreen();
      case AppNavScreen.finance:
        return const ExpensesScreen();
      case AppNavScreen.reports:
        return const XReportScreen();
      case AppNavScreen.approvals:
        return const ApprovalsScreen();
    }
  }
}
