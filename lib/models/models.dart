import 'package:flutter/material.dart';

/// Core domain models for ThreadPOS.

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
  });

  final String id;
  final List<SaleLine> lines;
  final double total;
  final PaymentMethod method;
  final DateTime time;
  final String seller;

  int get itemCount =>
      lines.fold(0, (int sum, SaleLine l) => sum + l.qty);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'lines': lines.map((SaleLine l) => l.toJson()).toList(),
        'total': total,
        'method': method.name,
        'time': time.millisecondsSinceEpoch,
        'seller': seller,
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
      );
}

class Employee {
  Employee({
    required this.name,
    required this.title,
    required this.branch,
    required this.shift,
    required this.todaySales,
  });

  final String name;
  final String title;
  final String branch;
  final String shift;
  final double todaySales;

  String get initial => name.isEmpty ? '?' : name[0];
  double get commission => todaySales * 0.03;
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
