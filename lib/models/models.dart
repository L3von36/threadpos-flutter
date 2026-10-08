import 'package:flutter/material.dart';

/// Core domain models for Sami POS.

enum UserRole { seller, manager }

UserRole userRoleFromString(String? s) =>
    s == 'manager' ? UserRole.manager : UserRole.seller;

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
  });

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

class Employee {
  Employee({
    required this.name,
    required this.title,
    required this.branch,
    required this.shift,
    required this.todaySales,
    this.orders = 0,
    this.conversion = 0,
  });

  final String name;
  final String title;
  final String branch;
  final String shift;
  final double todaySales;

  /// Transactions closed today (for the employee detail screen).
  final int orders;

  /// Browsers-to-buyers conversion rate, in percent.
  final int conversion;

  String get initial => name.isEmpty ? '?' : name[0];

  double commissionAt(double ratePct) => todaySales * ratePct / 100;

  double get commission => commissionAt(3);
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
