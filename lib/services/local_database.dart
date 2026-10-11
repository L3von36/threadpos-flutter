import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';

/// Local persistence and offline transaction sync engine powered by Hive.
///
/// Ensures the POS remains 100% operational during internet outages:
/// - Persists catalog, inventory, and sales locally into binary-indexed Hive boxes.
/// - Queues offline transactions in a dedicated sync box.
/// - Monitors connection status via [connectivity_plus] and supports simulated outages.
/// - Automatically or manually synchronizes queued transactions upon reconnection.
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const String _boxProducts = 'pos_products_v1';
  static const String _boxSales = 'pos_sales_v1';
  static const String _boxOfflineQueue = 'pos_offline_queue_v1';
  static const String _boxMeta = 'pos_meta_v1';

  late Box<Map> _productsBox;
  late Box<Map> _salesBox;
  late Box<Map> _offlineQueueBox;
  late Box<dynamic> _metaBox;

  bool _initialized = false;
  bool _isHardwareOffline = false;
  bool _isSimulatedOffline = false;

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Stream emitting connectivity status (true = online, false = offline).
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// True if currently disconnected from internet or in simulated outage.
  bool get isOffline => _isSimulatedOffline || _isHardwareHardwareOffline;
  bool get isHardwareOffline => _isHardwareOffline;
  bool get _isHardwareHardwareOffline => _isHardwareOffline;
  bool get isSimulatedOffline => _isSimulatedOffline;

  int get pendingOfflineCount =>
      _initialized ? _offlineQueueBox.length : 0;
  int get cachedProductsCount =>
      _initialized ? _productsBox.length : 0;
  int get cachedSalesCount =>
      _initialized ? _salesBox.length : 0;

  /// Initializes Hive storage and network monitoring.
  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    _productsBox = await Hive.openBox<Map>(_boxProducts);
    _salesBox = await Hive.openBox<Map>(_boxSales);
    _offlineQueueBox = await Hive.openBox<Map>(_boxOfflineQueue);
    _metaBox = await Hive.openBox<dynamic>(_boxMeta);

    _initialized = true;

    // Initialize connectivity check
    try {
      final List<ConnectivityResult> results =
          await Connectivity().checkConnectivity();
      _isHardwareOffline = _evaluateOffline(results);
    } catch (e) {
      debugPrint('Connectivity check init failed: $e');
      _isHardwareOffline = false;
    }

    // Subscribe to connectivity changes
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final bool nowOffline = _evaluateOffline(results);
      final bool prevEffectiveOffline = isOffline;
      _isHardwareOffline = nowOffline;
      final bool newEffectiveOffline = isOffline;

      if (prevEffectiveOffline != newEffectiveOffline) {
        _connectivityController.add(!newEffectiveOffline);
      }
    });
  }

  bool _evaluateOffline(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return !results.any((ConnectivityResult r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  /// Toggles simulated offline mode to easily test POS functionality
  /// and sync workflows during internet outages.
  void setSimulatedOffline(bool simulate) {
    if (_isSimulatedOffline == simulate) return;
    final bool prevStatus = isOffline;
    _isSimulatedOffline = simulate;
    final bool newStatus = isOffline;

    if (prevStatus != newStatus) {
      _connectivityController.add(!newStatus);
    }
  }

  // ---------- Thread & Product persistence (Hive) ----------

  /// Persists thread / clothing catalog data into Hive for offline availability.
  Future<void> saveThreads(List<Product> threads) async => saveProducts(threads);

  /// Loads locally cached threads from Hive storage.
  List<Product> loadThreads() => loadProducts();

  // ---------- Product persistence ----------

  Future<void> saveProducts(List<Product> products) async {
    if (!_initialized) return;
    final Map<String, Map<String, dynamic>> map = <String, Map<String, dynamic>>{};
    for (final Product p in products) {
      map[p.id] = p.toJson();
    }
    await _productsBox.putAll(map);
  }

  List<Product> loadProducts() {
    if (!_initialized || _productsBox.isEmpty) return <Product>[];
    final List<Product> list = <Product>[];
    for (final dynamic raw in _productsBox.values) {
      try {
        if (raw is Map) {
          final Map<String, dynamic> json =
              Map<String, dynamic>.from(raw);
          list.add(Product.fromJson(json));
        }
      } catch (e) {
        debugPrint('Error decoding cached product: $e');
      }
    }
    return list;
  }

  // ---------- Sales & Offline Queue persistence ----------

  /// Persists a new sale into Hive.
  /// If [sale.isSynced] is false (e.g. recorded during an outage),
  /// it is queued in the offline transactions box.
  Future<void> recordSale(Sale sale) async {
    if (!_initialized) return;
    final Map<String, dynamic> json = sale.toJson();
    await _salesBox.put(sale.id, json);

    if (!sale.isSynced) {
      await _offlineQueueBox.put(sale.id, json);
    }
  }

  Future<void> saveAllSales(List<Sale> sales) async {
    if (!_initialized) return;
    final Map<String, Map<String, dynamic>> map =
        <String, Map<String, dynamic>>{};
    for (final Sale s in sales) {
      map[s.id] = s.toJson();
    }
    await _salesBox.putAll(map);
  }

  List<Sale> loadSales() {
    if (!_initialized || _salesBox.isEmpty) return <Sale>[];
    final List<Sale> list = <Sale>[];
    for (final dynamic raw in _salesBox.values) {
      try {
        if (raw is Map) {
          final Map<String, dynamic> json =
              Map<String, dynamic>.from(raw);
          list.add(Sale.fromJson(json));
        }
      } catch (e) {
        debugPrint('Error decoding cached sale: $e');
      }
    }
    return list;
  }

  List<Sale> loadOfflineQueue() {
    if (!_initialized || _offlineQueueBox.isEmpty) return <Sale>[];
    final List<Sale> list = <Sale>[];
    for (final dynamic raw in _offlineQueueBox.values) {
      try {
        if (raw is Map) {
          final Map<String, dynamic> json =
              Map<String, dynamic>.from(raw);
          list.add(Sale.fromJson(json));
        }
      } catch (e) {
        debugPrint('Error decoding queued offline sale: $e');
      }
    }
    return list;
  }

  /// Marks a pending transaction as synchronized and removes it from the offline queue.
  Future<void> markTransactionSynced(String saleId, DateTime syncedAt) async {
    if (!_initialized) return;
    final dynamic existing = _salesBox.get(saleId);
    if (existing is Map) {
      final Map<String, dynamic> json = Map<String, dynamic>.from(existing);
      json['isSynced'] = true;
      json['syncedAt'] = syncedAt.millisecondsSinceEpoch;
      await _salesBox.put(saleId, json);
    }
    await _offlineQueueBox.delete(saleId);
  }

  /// Synchronizes all pending offline transactions.
  /// Simulates cloud API transmission, updates local records,
  /// and clears the queue upon completion.
  Future<int> syncAllPendingTransactions() async {
    if (!_initialized || _offlineQueueBox.isEmpty) return 0;
    final List<Sale> pending = loadOfflineQueue();
    if (pending.isEmpty) return 0;

    // Simulate network transmission delay
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final DateTime now = DateTime.now();
    for (final Sale s in pending) {
      await markTransactionSynced(s.id, now);
    }

    await setMeta('last_sync_time', now.millisecondsSinceEpoch);
    return pending.length;
  }

  // ---------- Metadata & Preferences ----------

  Future<void> setMeta(String key, dynamic value) async {
    if (!_initialized) return;
    await _metaBox.put(key, value);
  }

  dynamic getMeta(String key, {dynamic defaultValue}) {
    if (!_initialized) return defaultValue;
    return _metaBox.get(key, defaultValue: defaultValue);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _connectivityController.close();
  }
}
