import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/models.dart';

/// Central app state: catalog, cart, sales history, auth role and
/// lightweight JSON persistence via SharedPreferences.
class Store extends ChangeNotifier {
  static const double shiftTarget = 15000;

  static const String _kRole = 'tp_role';
  static const String _kEmail = 'tp_email';
  static const String _kProducts = 'tp_products';
  static const String _kSales = 'tp_sales';
  static const String _kThemeMode = 'tp_theme_mode';

  final List<Product> _products = <Product>[];
  final List<Sale> _sales = <Sale>[];
  final List<CartItem> _cart = <CartItem>[];

  UserRole? role;
  String email = '';
  ThemeMode _themeMode = ThemeMode.system;

  // ---------- exposed state ----------

  List<Product> get products => List.unmodifiable(_products);
  List<Sale> get sales => List.unmodifiable(_sales);
  List<CartItem> get cart => List.unmodifiable(_cart);

  int get cartCount =>
      _cart.fold(0, (int s, CartItem i) => s + i.qty);
  double get cartTotal =>
      _cart.fold(0.0, (double s, CartItem i) => s + i.lineTotal);

  bool get isManager => role == UserRole.manager;
  bool get isLoggedIn => role != null;

  /// Light / dark / follow-system appearance, persisted across sessions.
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    unawaited(_persistThemeMode());
  }

  List<Employee> get employees => seedEmployees;
  List<Branch> get branches => seedBranches;
  List<ShiftSlot> get schedule => seedSchedule;

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

    _ensureTodaySales();
    notifyListeners();
  }

  void _seedSales() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    _sales
      ..clear()
      ..addAll(generateSales(day: today, count: 16, seed: 7));
    _sales.addAll(generateSales(
        day: today.subtract(const Duration(days: 1)), count: 22, seed: 11));
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRole);
    await prefs.remove(_kEmail);
    notifyListeners();
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
  Sale checkout(PaymentMethod method) {
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
      seller: email.isEmpty ? 'you' : email.split('@').first,
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
    notifyListeners();
    unawaited(_persist());
    return sale;
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

  /// Revenue buckets for 9:00 through 20:00 (12 hourly slots).
  List<double> get revenueByHour {
    final List<double> buckets = List<double>.filled(12, 0);
    for (final Sale s in todaySales) {
      final int h = s.time.hour;
      if (h >= 9 && h < 21) buckets[h - 9] += s.total;
    }
    return buckets;
  }

  Map<PaymentMethod, double> get paymentMix {
    final Map<PaymentMethod, double> mix = <PaymentMethod, double>{
      for (final PaymentMethod m in PaymentMethod.values) m: 0,
    };
    for (final Sale s in todaySales) {
      mix[s.method] = (mix[s.method] ?? 0) + s.total;
    }
    return mix;
  }

  List<MapEntry<Product, int>> get topProducts {
    final Map<String, int> qtyByName = <String, int>{};
    for (final Sale s in todaySales) {
      for (final SaleLine l in s.lines) {
        qtyByName[l.name] = (qtyByName[l.name] ?? 0) + l.qty;
      }
    }
    final List<MapEntry<Product, int>> entries = <MapEntry<Product, int>>[];
    for (final MapEntry<String, int> e in qtyByName.entries) {
      final Iterable<Product> matches =
          _products.where((Product p) => p.name == e.key);
      if (matches.isNotEmpty) {
        entries.add(MapEntry<Product, int>(matches.first, e.value));
      }
    }
    entries.sort((MapEntry<Product, int> a, MapEntry<Product, int> b) =>
        b.value.compareTo(a.value));
    return entries.take(4).toList();
  }

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
  }
}
