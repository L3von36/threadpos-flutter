import 'package:flutter/material.dart';

/// Core domain models for Sami POS.

enum UserRole { seller, manager }

UserRole userRoleFromString(String? s) =>
    s == 'manager' ? UserRole.manager : UserRole.seller;

/// Lifecycle of a clothing item in the catalog.
/// Seller-added pieces start [pending] until a manager approves them.
enum ProductStatus { pending, approved, rejected }

ProductStatus productStatusFromString(String? s) => switch (s) {
      'pending' => ProductStatus.pending,
      'rejected' => ProductStatus.rejected,
      _ => ProductStatus.approved,
    };

enum PaymentMethod { cash, card, mobile }

PaymentMethod paymentMethodFromString(String s) {
  switch (s) {
    case 'card':
      return PaymentMethod.card;
    case 'mobile':
      return PaymentMethod.mobile;
    default:
      return PaymentMethod.cash;
  }
}

String paymentMethodLabel(PaymentMethod m) {
  switch (m) {
    case PaymentMethod.cash:
      return 'Cash';
    case PaymentMethod.card:
      return 'Card';
    case PaymentMethod.mobile:
      return 'Mobile';
  }
}

IconData paymentMethodIcon(PaymentMethod m) {
  switch (m) {
    case PaymentMethod.cash:
      return Icons.payments_outlined;
    case PaymentMethod.card:
      return Icons.credit_card;
    case PaymentMethod.mobile:
      return Icons.smartphone;
  }
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.barcode,
    required this.imageUrl,
    this.description = '',
    this.sizes = const <String>['S', 'M', 'L', 'XL'],
    this.tag = '',
    this.status = ProductStatus.approved,
    this.addedBy = '',
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  final String id;
  final String name;
  final String category;
  final double price;
  int stock;
  String barcode;
  final String imageUrl;
  final String description;
  final List<String> sizes;

  /// Merchandising badge shown on the Sell grid:
  /// '' | 'New in' | 'Best seller'.
  final String tag;

  /// Approval lifecycle — sellers submit, managers decide.
  ProductStatus status;

  /// Who submitted the piece (email or display name), '' for seeds.
  String addedBy;

  /// When the piece was submitted.
  final DateTime addedAt;

  bool get isNew => tag == 'New in';
  bool get isBestSeller => tag == 'Best seller';

  /// How many units are on the floor, phrased like the reference UI.
  String get floorLabel {
    if (isOutOfStock) return 'Out of stock';
    if (isLowStock) return 'Low · $stock left';
    return '$stock available on floor';
  }

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => !isOutOfStock && stock <= 5;

  String get stockLabel {
    if (isOutOfStock) return 'Out of stock';
    if (isLowStock) return 'Low · $stock left';
    return '$stock in stock';
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    int? stock,
    String? barcode,
    String? imageUrl,
    String? description,
    List<String>? sizes,
    String? tag,
    ProductStatus? status,
    String? addedBy,
    DateTime? addedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      sizes: sizes ?? this.sizes,
      tag: tag ?? this.tag,
      status: status ?? this.status,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'barcode': barcode,
        'imageUrl': imageUrl,
        'description': description,
        'sizes': sizes,
        'tag': tag,
        'status': status.name,
        'addedBy': addedBy,
        'addedAt': addedAt.millisecondsSinceEpoch,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        price: (json['price'] as num).toDouble(),
        stock: (json['stock'] as num).toInt(),
        barcode: (json['barcode'] ?? '') as String,
        imageUrl: (json['imageUrl'] ?? '') as String,
        description: (json['description'] ?? '') as String,
        sizes: ((json['sizes'] ?? <dynamic>[]) as List<dynamic>)
            .map((dynamic e) => e.toString())
            .toList(),
        tag: (json['tag'] ?? '') as String,
        status: productStatusFromString(json['status'] as String?),
        addedBy: (json['addedBy'] ?? '') as String,
        addedAt: json['addedAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (json['addedAt'] as num).toInt()),
      );
}

class CartItem {
  CartItem({required this.product, required this.size, this.qty = 1});

  final Product product;
  final String size;
  int qty;

  double get lineTotal => product.price * qty;
}

class SaleLine {
  SaleLine({
    required this.name,
    required this.size,
    required this.qty,
    required this.price,
  });

  final String name;
  final String size;
  final int qty;
  final double price;

  double get lineTotal => price * qty;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'size': size,
        'qty': qty,
        'price': price,
      };

  factory SaleLine.fromJson(Map<String, dynamic> json) => SaleLine(
        name: json['name'] as String,
        size: (json['size'] ?? '') as String,
        qty: (json['qty'] as num).toInt(),
        price: (json['price'] as num).toDouble(),
      );
}

class Sale {
  Sale({
    required this.id,
    required this.lines,
    required this.total,
    required this.method,
    required this.time,
    required this.seller,
    this.discount = 0,
    this.receiptPref = 'print',
  });

  final String id;
  final List<SaleLine> lines;
  final double total;
  final PaymentMethod method;
  final DateTime time;
  final String seller;

  /// Amount removed by a cart-level discount, if any.
  final double discount;

  /// 'print' | 'text' | 'skip' — chosen on the payment screen.
  final String receiptPref;

  /// Gross value before the discount was applied.
  double get subtotal => total + discount;

  int get itemCount =>
      lines.fold(0, (int sum, SaleLine l) => sum + l.qty);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'lines': lines.map((SaleLine l) => l.toJson()).toList(),
        'total': total,
        'method': method.name,
        'time': time.millisecondsSinceEpoch,
        'seller': seller,
        'discount': discount,
        'receiptPref': receiptPref,
      };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'] as String,
        lines: ((json['lines'] ?? <dynamic>[]) as List<dynamic>)
            .map((dynamic e) => SaleLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num).toDouble(),
        method: paymentMethodFromString((json['method'] ?? 'cash') as String),
        time:
            DateTime.fromMillisecondsSinceEpoch((json['time'] as num).toInt()),
        seller: (json['seller'] ?? '') as String,
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        receiptPref: (json['receiptPref'] ?? 'print') as String,
      );
}

/// Employment state shown in the team roster and detail screen.
enum EmployeeStatus { active, onLeave, inactive }

String employeeStatusLabel(EmployeeStatus s) => switch (s) {
      EmployeeStatus.active => 'Active',
      EmployeeStatus.onLeave => 'On leave',
      EmployeeStatus.inactive => 'Inactive',
    };

class Employee {
  Employee({
    required this.name,
    required this.title,
    required this.branch,
    required this.shift,
    required this.todaySales,
    this.id = '',
    this.orders = 0,
    this.conversion = 0,
    this.phone = '',
    this.pin = '1234',
    this.status = EmployeeStatus.active,
    DateTime? joinedOn,
  }) : joinedOn = joinedOn ?? DateTime(2024, 3, 1);

  final String name;
  final String title;
  final String branch;
  final String shift;
  final double todaySales;

  /// Stable identifier for editing from the roster.
  final String id;

  /// Transactions closed today (for the employee detail screen).
  final int orders;

  /// Browsers-to-buyers conversion rate, in percent.
  final int conversion;

  String phone;

  /// Register/login PIN — editable by the manager.
  String pin;

  EmployeeStatus status;
  final DateTime joinedOn;

  String get initial => name.isEmpty ? '?' : name[0];

  /// First name — matches how sales attribute the seller.
  String get firstName =>
      name.isEmpty ? '' : name.split(' ').first.toLowerCase();

  double commissionAt(double ratePct) => todaySales * ratePct / 100;

  double get commission => commissionAt(3);

  Employee copyWith({
    String? name,
    String? title,
    String? branch,
    String? shift,
    double? todaySales,
    int? orders,
    int? conversion,
    String? phone,
    String? pin,
    EmployeeStatus? status,
  }) {
    return Employee(
      id: id,
      name: name ?? this.name,
      title: title ?? this.title,
      branch: branch ?? this.branch,
      shift: shift ?? this.shift,
      todaySales: todaySales ?? this.todaySales,
      orders: orders ?? this.orders,
      conversion: conversion ?? this.conversion,
      phone: phone ?? this.phone,
      pin: pin ?? this.pin,
      status: status ?? this.status,
      joinedOn: joinedOn,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'title': title,
        'branch': branch,
        'shift': shift,
        'todaySales': todaySales,
        'orders': orders,
        'conversion': conversion,
        'phone': phone,
        'pin': pin,
        'status': status.name,
        'joinedOn': joinedOn.millisecondsSinceEpoch,
      };

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: (json['id'] ?? '') as String,
        name: json['name'] as String,
        title: json['title'] as String,
        branch: json['branch'] as String,
        shift: json['shift'] as String,
        todaySales: (json['todaySales'] as num?)?.toDouble() ?? 0,
        orders: (json['orders'] as num?)?.toInt() ?? 0,
        conversion: (json['conversion'] as num?)?.toInt() ?? 0,
        phone: (json['phone'] ?? '') as String,
        pin: (json['pin'] ?? '1234') as String,
        status: EmployeeStatus.values.firstWhere(
          (EmployeeStatus s) => s.name == (json['status'] as String?),
          orElse: () => EmployeeStatus.active,
        ),
        joinedOn: json['joinedOn'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (json['joinedOn'] as num).toInt()),
      );
}

/// Inter-location stock movement shown in the transfer queue.
class TransferOrder {
  TransferOrder({
    required this.id,
    required this.productName,
    required this.qty,
    required this.from,
    required this.to,
    this.inTransit = true,
  });

  final String id;
  final String productName;
  final int qty;
  final String from;
  final String to;
  final bool inTransit;
}

/// Generic row for the manager ops screens (approvals, audit log,
/// catalog updates, alerts, offline sync queue).
class OpsItem {
  OpsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.meta = '',
  });

  final String title;
  final String subtitle;
  final String meta;
  final IconData icon;
}

class Branch {
  Branch({
    required this.name,
    required this.manager,
    required this.revenue,
    required this.target,
    required this.staff,
  });

  final String name;
  final String manager;
  final double revenue;
  final double target;
  final int staff;

  double get progress {
    if (target <= 0) return 0;
    final double r = revenue / target;
    if (r < 0) return 0;
    if (r > 1) return 1;
    return r;
  }
}

class ShiftSlot {
  ShiftSlot({required this.day, required this.name, required this.time});

  /// 1 = Monday ... 7 = Sunday (matches DateTime.weekday).
  final int day;
  final String name;
  final String time;
}

/// Money the boutique spends — rent, salaries, utilities and so on.
class Expense {
  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.time,
    this.branch = 'Bole Flagship',
    this.note = '',
    this.recordedBy = '',
  });

  final String id;
  final String title;

  /// Rent | Salaries | Utilities | Supplies | Marketing | Maintenance | Other
  final String category;
  final double amount;
  final DateTime time;
  final String branch;
  final String note;
  final String recordedBy;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'category': category,
        'amount': amount,
        'time': time.millisecondsSinceEpoch,
        'branch': branch,
        'note': note,
        'recordedBy': recordedBy,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        time: DateTime.fromMillisecondsSinceEpoch(
            (json['time'] as num).toInt()),
        branch: (json['branch'] ?? 'Bole Flagship') as String,
        note: (json['note'] ?? '') as String,
        recordedBy: (json['recordedBy'] ?? '') as String,
      );
}

/// Money coming in that is not a point-of-sale sale — alterations,
/// consignment payouts, wholesale orders...
class IncomeEntry {
  IncomeEntry({
    required this.id,
    required this.title,
    required this.source,
    required this.amount,
    required this.time,
    this.branch = 'Bole Flagship',
    this.recordedBy = '',
  });

  final String id;
  final String title;
  final String source;
  final double amount;
  final DateTime time;
  final String branch;
  final String recordedBy;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'source': source,
        'amount': amount,
        'time': time.millisecondsSinceEpoch,
        'branch': branch,
        'recordedBy': recordedBy,
      };

  factory IncomeEntry.fromJson(Map<String, dynamic> json) => IncomeEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        source: json['source'] as String,
        amount: (json['amount'] as num).toDouble(),
        time: DateTime.fromMillisecondsSinceEpoch(
            (json['time'] as num).toInt()),
        branch: (json['branch'] ?? 'Bole Flagship') as String,
        recordedBy: (json['recordedBy'] ?? '') as String,
      );
}

/// A printed shift snapshot.
///
/// Type 'X' is a read-only mid-shift reading — the drawer stays open.
/// Type 'Z' closes the register for the day and locks in the counted
/// cash with its variance.
class ShiftReport {
  ShiftReport({
    required this.id,
    required this.type,
    required this.time,
    required this.register,
    required this.cashier,
    required this.transactions,
    required this.itemsSold,
    required this.grossSales,
    required this.discounts,
    required this.netSales,
    required this.cash,
    required this.card,
    required this.mobile,
    required this.openingFloat,
    this.countedCash = -1,
    this.variance = 0,
    this.note = '',
  });

  final String id; // 'X-3' / 'Z-2'
  final String type; // 'X' | 'Z'
  final DateTime time;
  final String register;
  final String cashier;
  final int transactions;
  final int itemsSold;
  final double grossSales;
  final double discounts;
  final double netSales;
  final double cash;
  final double card;
  final double mobile;
  final double openingFloat;

  /// Z only — what the manager physically counted.
  final double countedCash;

  /// Z only — countedCash minus expected drawer.
  final double variance;
  final String note;

  double get expectedDrawer => openingFloat + cash;

  double get avgOrder =>
      transactions == 0 ? 0 : netSales / transactions;

  bool get isZ => type == 'Z';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'time': time.millisecondsSinceEpoch,
        'register': register,
        'cashier': cashier,
        'transactions': transactions,
        'itemsSold': itemsSold,
        'grossSales': grossSales,
        'discounts': discounts,
        'netSales': netSales,
        'cash': cash,
        'card': card,
        'mobile': mobile,
        'openingFloat': openingFloat,
        'countedCash': countedCash,
        'variance': variance,
        'note': note,
      };

  factory ShiftReport.fromJson(Map<String, dynamic> json) => ShiftReport(
        id: json['id'] as String,
        type: json['type'] as String,
        time: DateTime.fromMillisecondsSinceEpoch(
            (json['time'] as num).toInt()),
        register: json['register'] as String,
        cashier: json['cashier'] as String,
        transactions: (json['transactions'] as num?)?.toInt() ?? 0,
        itemsSold: (json['itemsSold'] as num?)?.toInt() ?? 0,
        grossSales: (json['grossSales'] as num?)?.toDouble() ?? 0,
        discounts: (json['discounts'] as num?)?.toDouble() ?? 0,
        netSales: (json['netSales'] as num?)?.toDouble() ?? 0,
        cash: (json['cash'] as num?)?.toDouble() ?? 0,
        card: (json['card'] as num?)?.toDouble() ?? 0,
        mobile: (json['mobile'] as num?)?.toDouble() ?? 0,
        openingFloat: (json['openingFloat'] as num?)?.toDouble() ?? 0,
        countedCash: (json['countedCash'] as num?)?.toDouble() ?? -1,
        variance: (json['variance'] as num?)?.toDouble() ?? 0,
        note: (json['note'] ?? '') as String,
      );
}

/// In-app notification produced by the approval pipeline and the
/// day-close flow — surfaced on the bell for the matching role.
class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.time,
    this.forManagers = true,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;

  /// 'submit' | 'approved' | 'rejected' | 'dayClosed'
  final String kind;
  final DateTime time;

  /// True -> rings on the manager bell; false -> on the seller bell.
  final bool forManagers;
  bool read;

  IconData get icon => switch (kind) {
        'submit' => Icons.new_releases_outlined,
        'approved' => Icons.check_circle_outline,
        'rejected' => Icons.cancel_outlined,
        _ => Icons.lock_clock_outlined,
      };

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        kind: kind,
        time: time,
        forManagers: forManagers,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'body': body,
        'kind': kind,
        'time': time.millisecondsSinceEpoch,
        'forManagers': forManagers,
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        kind: (json['kind'] ?? 'submit') as String,
        time: DateTime.fromMillisecondsSinceEpoch(
            (json['time'] as num?)?.toInt() ?? 0),
        forManagers: (json['forManagers'] ?? true) as bool,
        read: (json['read'] ?? false) as bool,
      );
}
