import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/models.dart';

/// Rolling analytics window for the dashboards.
enum SalesRange { today, d7, d30 }

extension SalesRangeX on SalesRange {
  int get days => switch (this) {
        SalesRange.today => 1,
        SalesRange.d7 => 7,
        SalesRange.d30 => 30,
      };

  String get label => switch (this) {
        SalesRange.today => 'Today',
        SalesRange.d7 => '7 days',
        SalesRange.d30 => '30 days',
      };
}

/// A ranked product for the "What is moving" section.
class TopProduct {
  TopProduct({required this.product, required this.qty, required this.revenue});

  final Product product;
  final int qty;
  final double revenue;
}

/// Central app state: catalog, cart, sales history, auth role and
/// lightweight JSON persistence via SharedPreferences.
class Store extends ChangeNotifier {
  static const double shiftTarget = 15000;

  /// Boutique locations used by the manager network-stock view.
  static const List<String> locations = <String>[
    'Bole Flagship',
    'Kazanchis',
    'Megenagna',
  ];

  static const String _kRole = 'tp_role';
  static const String _kEmail = 'tp_email';
  static const String _kProducts = 'tp_products';
  static const String _kSales = 'tp_sales';
  static const String _kThemeMode = 'tp_theme_mode';
  static const String _kPendingProducts = 'tp_pending_products';
  static const String _kEmployees = 'tp_employees';
  static const String _kExpenses = 'tp_expenses';
  static const String _kIncomes = 'tp_incomes';
  static const String _kReports = 'tp_reports';
  static const String _kSettings = 'tp_settings';

  final List<Product> _products = <Product>[];
  final List<Product> _pendingProducts = <Product>[];
  final List<Sale> _sales = <Sale>[];
  final List<CartItem> _cart = <CartItem>[];
  final List<Product> _recentLookups = <Product>[];
  final Set<String> _restockRequested = <String>{};
  List<TransferOrder> _transfers = <TransferOrder>[];
  final List<Employee> _employees = <Employee>[];
  final List<Expense> _expenses = <Expense>[];
  final List<IncomeEntry> _incomes = <IncomeEntry>[];
  final List<ShiftReport> _reports = <ShiftReport>[];
  double _dailyTarget = shiftTarget;
  double _commissionRate = 3;
  DateTime _lastSync = DateTime.now().subtract(const Duration(minutes: 2));
  double _discountPct = 0;

  UserRole? role;
  String email = '';
  ThemeMode _themeMode = ThemeMode.system;

  // ---------- exposed state ----------

  List<Product> get products => List.unmodifiable(_products);
  List<Sale> get sales => List.unmodifiable(_sales);
  List<CartItem> get cart => List.unmodifiable(_cart);

  /// Products found via the Scan tab during this shift (most recent first).
  List<Product> get recentLookups => List.unmodifiable(_recentLookups);

  List<TransferOrder> get transfers => List.unmodifiable(_transfers);

  /// Pieces submitted by sellers that await a manager decision.
  List<Product> get pendingProducts => List.unmodifiable(_pendingProducts);

  int get pendingProductCount => _pendingProducts.length;

  /// Full roster — editable from the Employees module.
  List<Employee> get employees => List.unmodifiable(_employees);

  List<Expense> get expenses {
    final List<Expense> copy = List<Expense>.from(_expenses)
      ..sort((Expense a, Expense b) => b.time.compareTo(a.time));
    return List.unmodifiable(copy);
  }

  List<IncomeEntry> get incomes {
    final List<IncomeEntry> copy = List<IncomeEntry>.from(_incomes)
      ..sort((IncomeEntry a, IncomeEntry b) => b.time.compareTo(a.time));
    return List.unmodifiable(copy);
  }

  /// Archived shift reports — newest first.
  List<ShiftReport> get reports {
    final List<ShiftReport> copy = List<ShiftReport>.from(_reports)
      ..sort((ShiftReport a, ShiftReport b) => b.time.compareTo(a.time));
    return List.unmodifiable(copy);
  }

  List<ShiftReport> get zReports => reports
      .where((ShiftReport r) => r.isZ)
      .toList(growable: false);

  /// Seller-facing daily goal — editable from Performance.
  double get dailyTarget => _dailyTarget;

  /// Commission percent applied in the Performance module.
  double get commissionRate => _commissionRate;

  DateTime get lastSync => _lastSync;

  /// Human label for the network-sync status card.
  String get syncedLabel {
    final Duration d = DateTime.now().difference(_lastSync);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes == 1) return '1 min ago';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    return '${d.inHours}h ago';
  }

  void syncNow() {
    _lastSync = DateTime.now();
    notifyListeners();
  }

  int get cartCount =>
      _cart.fold(0, (int s, CartItem i) => s + i.qty);

  /// Cart value before any discount.
  double get cartSubtotal =>
      _cart.fold(0.0, (double s, CartItem i) => s + i.lineTotal);

  /// Cart-level discount percent (0-100), set from the cart screen.
  double get discountPct => _discountPct;

  double get cartDiscount => cartSubtotal * _discountPct / 100;

  /// Payable total after the cart discount.
  double get cartTotal => cartSubtotal * (1 - _discountPct / 100);

  void setDiscountPct(double pct) {
    _discountPct = pct.clamp(0, 50).toDouble();
    notifyListeners();
  }

  bool get isManager => role == UserRole.manager;
  bool get isLoggedIn => role != null;

  /// First name shown in the Sell greeting.
  String get displayName {
    if (email.isEmpty) return 'Maya';
    final String raw = email.split('@').first;
    if (raw.isEmpty) return 'Maya';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  /// Light / dark / follow-system appearance, persisted across sessions.
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    unawaited(_persistThemeMode());
  }

  List<Branch> get branches => seedBranches;
  List<ShiftSlot> get schedule => seedSchedule;
  List<OpsItem> get approvals => seedApprovals;
  List<OpsItem> get auditLog => seedAuditLog;
  List<OpsItem> get catalogUpdates => seedCatalogUpdates;
  List<OpsItem> get alerts => seedAlerts;
  List<OpsItem> get offlineQueue => seedOfflineQueue;

  // ---------- product approval workflow ----------

  /// Sellers submit pieces for review; managers publish instantly.
  void submitProduct(Product product) {
    if (isManager) {
      addProduct(product);
      return;
    }
    _pendingProducts.insert(0, product);
    notifyListeners();
    unawaited(_persist());
  }

  /// Manager decision — approve moves the piece into the live catalog.
  void approveProduct(String productId) {
    final int idx =
        _pendingProducts.indexWhere((Product p) => p.id == productId);
    if (idx < 0) return;
    final Product approved = _pendingProducts.removeAt(idx);
    _products.insert(
      0,
      approved.copyWith(
        status: ProductStatus.approved,
        tag: 'New in',
      ),
    );
    notifyListeners();
    unawaited(_persist());
  }

  /// Manager decision — decline drops the submission entirely.
  void rejectProduct(String productId) {
    _pendingProducts.removeWhere((Product p) => p.id == productId);
    notifyListeners();
    unawaited(_persist());
  }

  // ---------- employee management ----------

  void addEmployee(Employee employee) {
    _employees.insert(0, employee);
    notifyListeners();
    unawaited(_persist());
  }

  void updateEmployee(Employee employee) {
    final int idx =
        _employees.indexWhere((Employee e) => e.id == employee.id);
    if (idx < 0) return;
    _employees[idx] = employee;
    notifyListeners();
    unawaited(_persist());
  }

  void removeEmployee(String employeeId) {
    _employees.removeWhere((Employee e) => e.id == employeeId);
    notifyListeners();
    unawaited(_persist());
  }

  Employee? employeeById(String employeeId) {
    for (final Employee e in _employees) {
      if (e.id == employeeId) return e;
    }
    return null;
  }

  // ---------- performance settings ----------

  void setDailyTarget(double target) {
    _dailyTarget = target.clamp(500, 500000).toDouble();
    notifyListeners();
    unawaited(_persist());
  }

  void setCommissionRate(double ratePct) {
    _commissionRate = ratePct.clamp(0, 20).toDouble();
    notifyListeners();
    unawaited(_persist());
  }

  // ---------- expenses & income ----------

  void addExpense(Expense expense) {
    _expenses.insert(0, expense);
    notifyListeners();
    unawaited(_persist());
  }

  void removeExpense(String expenseId) {
    _expenses.removeWhere((Expense e) => e.id == expenseId);
    notifyListeners();
    unawaited(_persist());
  }

  void addIncome(IncomeEntry entry) {
    _incomes.insert(0, entry);
    notifyListeners();
    unawaited(_persist());
  }

  void removeIncome(String entryId) {
    _incomes.removeWhere((IncomeEntry e) => e.id == entryId);
    notifyListeners();
    unawaited(_persist());
  }

  double expensesTotalFor(SalesRange range) {
    final DateTime now = DateTime.now();
    final DateTime cutoff = now.subtract(Duration(days: range.days));
    return _expenses
        .where((Expense e) =>
            e.time.isAfter(cutoff) || _isSameDay(e.time, now))
        .fold(0.0, (double s, Expense e) => s + e.amount);
  }

  double otherIncomeFor(SalesRange range) {
    final DateTime now = DateTime.now();
    final DateTime cutoff = now.subtract(Duration(days: range.days));
    return _incomes
        .where((IncomeEntry e) =>
            e.time.isAfter(cutoff) || _isSameDay(e.time, now))
        .fold(0.0, (double s, IncomeEntry e) => s + e.amount);
  }

  // ---------- branch & seller analytics ----------

  /// Best-effort branch attribution: sale.seller is a first name that
  /// matches an employee's first name; unmatched sales land at the
  /// flagship.
  String branchForSale(Sale sale) {
    for (final Employee e in _employees) {
      if (e.firstName == sale.seller.toLowerCase()) return e.branch;
    }
    return locations.first;
  }

  List<Sale> salesForBranch(String branch, SalesRange range) =>
      salesForRange(range)
          .where((Sale s) => branchForSale(s) == branch)
          .toList(growable: false);

  double branchRevenue(String branch, SalesRange range) =>
      revenueFor(salesForBranch(branch, range));

  /// Sales closed by [sellerFirstName] inside [range] — real
  /// per-seller performance straight from the sale log.
  List<Sale> salesForSeller(String sellerFirstName, SalesRange range) =>
      salesForRange(range)
          .where((Sale s) =>
              s.seller.toLowerCase() == sellerFirstName.toLowerCase())
          .toList(growable: false);

  /// Revenue per seller first name inside [range], descending.
  Map<String, double> revenueBySellerFor(SalesRange range) {
    final Map<String, double> bySeller = <String, double>{};
    for (final Sale s in salesForRange(range)) {
      bySeller[s.seller] = (bySeller[s.seller] ?? 0) + s.total;
    }
    final List<MapEntry<String, double>> sorted = bySeller.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
          b.value.compareTo(a.value));
    return <String, double>{
      for (final MapEntry<String, double> e in sorted) e.key: e.value
    };
  }

  // ---------- X / Z shift reports ----------

  static const double openingFloat = 2000;
  static const String registerName = 'Register 1 · Bole Flagship';

  /// Builds the live snapshot from today's real sales.
  ShiftReport buildReport({required String type}) {
    final List<Sale> day = todaySales;
    final double gross =
        day.fold(0.0, (double s, Sale t) => s + t.subtotal);
    final double discounts =
        day.fold(0.0, (double s, Sale t) => s + t.discount);
    final Map<PaymentMethod, double> mix = paymentMixFor(day);
    final String seq = type == 'Z'
        ? 'Z-${119 + zReports.length}'
        : 'X-${1 + DateTime.now().difference(_startOfToday()).inHours}';
    return ShiftReport(
      id: seq,
      type: type,
      time: DateTime.now(),
      register: registerName,
      cashier: displayName,
      transactions: day.length,
      itemsSold: itemsFor(day),
      grossSales: gross,
      discounts: discounts,
      netSales: revenueFor(day),
      cash: mix[PaymentMethod.cash] ?? 0,
      card: mix[PaymentMethod.card] ?? 0,
      mobile: mix[PaymentMethod.mobile] ?? 0,
      openingFloat: openingFloat,
    );
  }

  /// Did a Z report already lock today?
  bool get dayClosedToday {
    final DateTime today = _startOfToday();
    return _reports.any((ShiftReport r) => r.isZ && r.time.isAfter(today));
  }

  /// Closes the register: locks a Z report into the archive.
  void closeDay({required double countedCash, String note = ''}) {
    final ShiftReport x = buildReport(type: 'Z');
    _reports.insert(
      0,
      ShiftReport(
        id: x.id,
        type: 'Z',
        time: DateTime.now(),
        register: x.register,
        cashier: x.cashier,
        transactions: x.transactions,
        itemsSold: x.itemsSold,
        grossSales: x.grossSales,
        discounts: x.discounts,
        netSales: x.netSales,
        cash: x.cash,
        card: x.card,
        mobile: x.mobile,
        openingFloat: x.openingFloat,
        countedCash: countedCash,
        variance: countedCash - x.expectedDrawer,
        note: note,
      ),
    );
    notifyListeners();
    unawaited(_persist());
  }

  DateTime _startOfToday() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ---------- lifecycle ----------

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? roleStr = prefs.getString(_kRole);
    role = roleStr == null ? null : userRoleFromString(roleStr);
    email = prefs.getString(_kEmail) ?? '';
    final String? themeStr = prefs.getString(_kThemeMode);
    _themeMode = themeStr == null
        ? ThemeMode.system
        : (ThemeMode.values.asNameMap()[themeStr] ?? ThemeMode.system);

    final String? rawProducts = prefs.getString(_kProducts);
    if (rawProducts != null) {
      try {
        final List<dynamic> list = jsonDecode(rawProducts) as List<dynamic>;
        _products
          ..clear()
          ..addAll(list
              .map((dynamic e) => Product.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        _products
          ..clear()
          ..addAll(seedProducts.map((Product p) => p.copyWith()));
      }
    } else {
      _products.addAll(seedProducts.map((Product p) => p.copyWith()));
    }

    final String? rawSales = prefs.getString(_kSales);
    if (rawSales != null) {
      try {
        final List<dynamic> list = jsonDecode(rawSales) as List<dynamic>;
        _sales
          ..clear()
          ..addAll(list
              .map((dynamic e) => Sale.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        _seedSales();
      }
    } else {
      _seedSales();
    }

    // Seller-submitted pieces awaiting approval.
    final String? rawPending = prefs.getString(_kPendingProducts);
    if (rawPending != null) {
      try {
        final List<dynamic> list = jsonDecode(rawPending) as List<dynamic>;
        _pendingProducts
          ..clear()
          ..addAll(list
              .map((dynamic e) => Product.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        _pendingProducts.clear();
      }
    }

    _loadEmployees(prefs);
    _loadExpenses(prefs);
    _loadIncomes(prefs);
    _loadReports(prefs);
    _loadSettings(prefs);

    _transfers = seedTransfers;
    _ensureTodaySales();
    notifyListeners();
  }

  void _loadEmployees(SharedPreferences prefs) {
    final String? raw = prefs.getString(_kEmployees);
    if (raw == null) {
      _employees
        ..clear()
        ..addAll(seedEmployees.map((Employee e) =>
            Employee.fromJson(e.toJson())));
      return;
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      _employees
        ..clear()
        ..addAll(
            list.map((dynamic e) => Employee.fromJson(e as Map<String, dynamic>)));
    } catch (_) {
      _employees
        ..clear()
        ..addAll(seedEmployees);
    }
  }

  void _loadExpenses(SharedPreferences prefs) {
    final String? raw = prefs.getString(_kExpenses);
    if (raw == null) {
      _expenses.addAll(seedExpenses);
      return;
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      _expenses
        ..clear()
        ..addAll(
            list.map((dynamic e) => Expense.fromJson(e as Map<String, dynamic>)));
    } catch (_) {
      _expenses..clear()..addAll(seedExpenses);
    }
  }

  void _loadIncomes(SharedPreferences prefs) {
    final String? raw = prefs.getString(_kIncomes);
    if (raw == null) {
      _incomes.addAll(seedIncomes);
      return;
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      _incomes
        ..clear()
        ..addAll(
            list.map((dynamic e) => IncomeEntry.fromJson(e as Map<String, dynamic>)));
    } catch (_) {
      _incomes..clear()..addAll(seedIncomes);
    }
  }

  void _loadReports(SharedPreferences prefs) {
    final String? raw = prefs.getString(_kReports);
    if (raw == null) {
      _reports.addAll(seedReports);
      return;
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      _reports
        ..clear()
        ..addAll(
            list.map((dynamic e) => ShiftReport.fromJson(e as Map<String, dynamic>)));
    } catch (_) {
      _reports..clear()..addAll(seedReports);
    }
  }

  void _loadSettings(SharedPreferences prefs) {
    final String? raw = prefs.getString(_kSettings);
    if (raw == null) return;
    try {
      final Map<String, dynamic> map =
          jsonDecode(raw) as Map<String, dynamic>;
      _dailyTarget = (map['dailyTarget'] as num?)?.toDouble() ?? shiftTarget;
      _commissionRate = (map['commissionRate'] as num?)?.toDouble() ?? 3;
    } catch (_) {
      // keep defaults
    }
  }

  void _seedSales() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    _sales
      ..clear()
      // 30 days of deterministic history so the 7/30-day analytics
      // windows are meaningful from the first launch.
      ..addAll(generateSales(day: today, count: 16, seed: 7));
    for (int i = 1; i < 30; i++) {
      _sales.addAll(generateSales(
        day: today.subtract(Duration(days: i)),
        count: 9 + (i * 5) % 11,
        seed: 100 + i,
      ));
    }
  }

  /// If the app was last used on a previous day, add a fresh batch of
  /// "this morning" sales so the dashboards stay meaningful.
  void _ensureTodaySales() {
    final DateTime now = DateTime.now();
    final bool hasToday = _sales.any((Sale s) => _isSameDay(s.time, now));
    if (hasToday) return;
    final DateTime today = DateTime(now.year, now.month, now.day);
    _sales.addAll(generateSales(day: today, count: 14, seed: 21 + now.day));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ---------- auth ----------

  Future<void> login(UserRole newRole, String newEmail) async {
    role = newRole;
    email = newEmail;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRole, newRole.name);
    await prefs.setString(_kEmail, newEmail);
    notifyListeners();
  }

  Future<void> logout() async {
    role = null;
    email = '';
    _cart.clear();
    _discountPct = 0;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRole);
    await prefs.remove(_kEmail);
    notifyListeners();
  }

  /// Jump between the Seller and Manager workspaces without signing out.
  Future<void> switchRole() async {
    final UserRole next =
        isManager ? UserRole.seller : UserRole.manager;
    await login(next, email);
  }

  // ---------- cart ----------

  void addToCart(Product product, {required String size, int qty = 1}) {
    for (final CartItem item in _cart) {
      if (item.product.id == product.id && item.size == size) {
        item.qty += qty;
        notifyListeners();
        return;
      }
    }
    _cart.add(CartItem(product: product, size: size, qty: qty));
    notifyListeners();
  }

  void changeQty(CartItem item, int delta) {
    item.qty += delta;
    if (item.qty <= 0) _cart.remove(item);
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _cart.remove(item);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  /// Completes the sale, decrements stock and returns the receipt.
  Sale checkout(PaymentMethod method, {String receiptPref = 'print'}) {
    final double discount = cartDiscount;
    final Sale sale = Sale(
      id: 'S${DateTime.now().millisecondsSinceEpoch % 100000}',
      lines: _cart
          .map((CartItem i) => SaleLine(
                name: i.product.name,
                size: i.size,
                qty: i.qty,
                price: i.product.price,
              ))
          .toList(),
      total: cartTotal,
      method: method,
      time: DateTime.now(),
      seller: email.isEmpty ? 'you' : displayName.toLowerCase(),
      discount: discount,
      receiptPref: receiptPref,
    );
    for (final CartItem item in _cart) {
      final int idx =
          _products.indexWhere((Product p) => p.id == item.product.id);
      if (idx >= 0) {
        final int next = _products[idx].stock - item.qty;
        _products[idx].stock = next < 0 ? 0 : next;
      }
    }
    _sales.add(sale);
    _cart.clear();
    _discountPct = 0;
    notifyListeners();
    unawaited(_persist());
    return sale;
  }

  /// Records a barcode lookup for the Scan tab's shift history.
  void pushLookup(Product product) {
    _recentLookups.removeWhere((Product p) => p.id == product.id);
    _recentLookups.insert(0, product);
    if (_recentLookups.length > 8) _recentLookups.removeLast();
    notifyListeners();
  }

  // ---------- restock requests & transfers ----------

  bool isRestockRequested(String productId) =>
      _restockRequested.contains(productId);

  void requestRestock(String productId) {
    _restockRequested.add(productId);
    notifyListeners();
  }

  int get incomingUnits => _transfers
      .where((TransferOrder t) => t.inTransit)
      .fold(0, (int s, TransferOrder t) => s + t.qty);

  void createTransfer(Product product, int qty, String to) {
    final int seq = 104 + _transfers.length;
    _transfers.insert(
      0,
      TransferOrder(
        id: 'TR-$seq',
        productName: product.name,
        qty: qty,
        from: locations.first,
        to: to,
      ),
    );
    notifyListeners();
  }

  /// Deterministic per-location share of a product's on-hand units.
  int unitsAt(Product product, int locationIndex) {
    if (locationIndex < 0 || locationIndex >= locations.length) {
      return product.stock;
    }
    const List<double> shares = <double>[0.5, 0.3, 0.2];
    final int total = product.stock;
    if (locationIndex == locations.length - 1) {
      final int used = total * 5 ~/ 10 + total * 3 ~/ 10;
      return total - used > 0 ? total - used : 0;
    }
    return (total * shares[locationIndex]).floor();
  }

  // ---------- catalog & stock ----------

  void addProduct(Product product) {
    _products.insert(0, product);
    notifyListeners();
    unawaited(_persist());
  }

  void adjustStock(String productId, int delta) {
    final int idx =
        _products.indexWhere((Product p) => p.id == productId);
    if (idx < 0) return;
    final int next = _products[idx].stock + delta;
    _products[idx].stock = next < 0 ? 0 : next;
    notifyListeners();
    unawaited(_persist());
  }

  Product? findByBarcode(String code) {
    final String q = code.trim();
    if (q.isEmpty) return null;
    for (final Product p in _products) {
      if (p.barcode == q) return p;
    }
    return null;
  }

  Product? findByName(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return null;
    for (final Product p in _products) {
      if (p.name.toLowerCase().contains(q)) return p;
    }
    return null;
  }

  // ---------- dashboard stats ----------

  List<Sale> get todaySales {
    final DateTime now = DateTime.now();
    return _sales.where((Sale s) => _isSameDay(s.time, now)).toList()
      ..sort((Sale a, Sale b) => b.time.compareTo(a.time));
  }

  double get todayRevenue =>
      todaySales.fold(0.0, (double s, Sale t) => s + t.total);

  int get todayItems => todaySales.fold(
      0, (int s, Sale t) => s + t.itemCount);

  // ---------- range analytics (Today / 7 days / 30 days) ----------

  /// Sales inside the rolling [range] window ending now, newest first.
  List<Sale> salesForRange(SalesRange range) {
    final DateTime now = DateTime.now();
    final DateTime cutoff =
        now.subtract(Duration(days: range.days));
    final DateTime dayStart = DateTime(
        cutoff.year, cutoff.month, cutoff.day);
    return _sales.where((Sale s) => s.time.isAfter(dayStart)).toList()
      ..sort((Sale a, Sale b) => b.time.compareTo(a.time));
  }

  double revenueFor(List<Sale> sales) =>
      sales.fold(0.0, (double s, Sale t) => s + t.total);

  int itemsFor(List<Sale> sales) =>
      sales.fold(0, (int s, Sale t) => s + t.itemCount);

  /// Revenue of the window immediately before [range] — used for the
  /// "vs previous period" deltas.
  double priorRevenueFor(SalesRange range) {
    final DateTime now = DateTime.now();
    final DateTime dayStart =
        DateTime(now.year, now.month, now.day);
    final DateTime curStart = dayStart
        .subtract(Duration(days: range.days - 1));
    final DateTime prevEnd = curStart
        .subtract(const Duration(microseconds: 1));
    final DateTime prevStart = prevEnd
        .subtract(Duration(days: range.days - 1));
    double sum = 0;
    for (final Sale s in _sales) {
      if (s.time.isAfter(prevStart) &&
          s.time.isBefore(prevEnd.add(const Duration(days: 1)))) {
        sum += s.total;
      }
    }
    return sum;
  }

  /// Percent change vs the previous window; null when no baseline.
  double? rangeDelta(SalesRange range) {
    final double prior = priorRevenueFor(range);
    if (prior <= 0) return null;
    final double cur = revenueFor(salesForRange(range));
    return (cur - prior) / prior * 100;
  }

  Map<PaymentMethod, double> paymentMixFor(List<Sale> sales) {
    final Map<PaymentMethod, double> mix = <PaymentMethod, double>{
      for (final PaymentMethod m in PaymentMethod.values) m: 0,
    };
    for (final Sale s in sales) {
      mix[s.method] = (mix[s.method] ?? 0) + s.total;
    }
    return mix;
  }

  /// Total revenue per day for the last [days] days, oldest first —
  /// used by the 7/30-day chart mode.
  List<double> revenueByDay(int days) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<double> buckets = List<double>.filled(days, 0);
    for (final Sale s in _sales) {
      final int age = today.difference(DateTime(s.time.year, s.time.month, s.time.day)).inDays;
      if (age >= 0 && age < days) {
        buckets[days - 1 - age] += s.total;
      }
    }
    return buckets;
  }

  /// Revenue buckets for 9:00 through 20:00 (12 hourly slots).
  List<double> get revenueByHour {
    final List<double> buckets = List<double>.filled(12, 0);
    for (final Sale s in todaySales) {
      final int h = s.time.hour;
      if (h >= 9 && h < 21) buckets[h - 9] += s.total;
    }
    return buckets;
  }

  Map<PaymentMethod, double> get paymentMix => paymentMixFor(todaySales);

  /// "What is moving" — products ranked by units sold inside [sales].
  List<TopProduct> topProductsFor(List<Sale> sales) {
    final Map<String, int> qtyByName = <String, int>{};
    final Map<String, double> revByName = <String, double>{};
    for (final Sale s in sales) {
      for (final SaleLine l in s.lines) {
        qtyByName[l.name] = (qtyByName[l.name] ?? 0) + l.qty;
        revByName[l.name] =
            (revByName[l.name] ?? 0) + l.price * l.qty;
      }
    }
    final List<TopProduct> entries = <TopProduct>[];
    for (final MapEntry<String, int> e in qtyByName.entries) {
      final Iterable<Product> matches =
          _products.where((Product p) => p.name == e.key);
      if (matches.isNotEmpty) {
        entries.add(TopProduct(
          product: matches.first,
          qty: e.value,
          revenue: revByName[e.key] ?? 0,
        ));
      }
    }
    entries.sort((TopProduct a, TopProduct b) =>
        b.qty.compareTo(a.qty));
    return entries.take(5).toList();
  }

  List<TopProduct> get topProducts => topProductsFor(todaySales);

  List<Product> get lowStockProducts =>
      _products.where((Product p) => p.isLowStock || p.isOutOfStock).toList();

  int get totalUnits => _products.fold(0, (int s, Product p) => s + p.stock);

  // ---------- persistence ----------

  Future<void> _persistThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, _themeMode.name);
  }

  Future<void> _persist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kProducts,
        jsonEncode(
            _products.map((Product p) => p.toJson()).toList()));
    await prefs.setString(
        _kSales,
        jsonEncode(_sales.map((Sale s) => s.toJson()).toList()));
    await prefs.setString(
        _kPendingProducts,
        jsonEncode(_pendingProducts
            .map((Product p) => p.toJson())
            .toList()));
    await prefs.setString(
        _kEmployees,
        jsonEncode(
            _employees.map((Employee e) => e.toJson()).toList()));
    await prefs.setString(
        _kExpenses,
        jsonEncode(
            _expenses.map((Expense e) => e.toJson()).toList()));
    await prefs.setString(
        _kIncomes,
        jsonEncode(
            _incomes.map((IncomeEntry e) => e.toJson()).toList()));
    await prefs.setString(
        _kReports,
        jsonEncode(
            _reports.map((ShiftReport r) => r.toJson()).toList()));
    await prefs.setString(
        _kSettings,
        jsonEncode(<String, dynamic>{
          'dailyTarget': _dailyTarget,
          'commissionRate': _commissionRate,
        }));
  }
}
