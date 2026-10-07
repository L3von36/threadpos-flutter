import 'dart:math';

import '../models/models.dart';

/// Seed catalog shown on first launch. Product photos are hosted on
/// Unsplash; the UI falls back to a styled placeholder when offline.

final List<Product> seedProducts = <Product>[
  Product(
    id: 'p1',
    name: 'Classic White Tee',
    category: 'Tops',
    price: 850,
    stock: 24,
    barcode: '6290100000013',
    imageUrl:
        'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600&q=80',
    description:
        'Soft combed cotton crew-neck tee with a relaxed boutique fit.',
    sizes: <String>['XS', 'S', 'M', 'L', 'XL'],
  ),
  Product(
    id: 'p2',
    name: 'Knit Cardigan',
    category: 'Outerwear',
    price: 2350,
    stock: 8,
    barcode: '6290100000020',
    imageUrl:
        'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=600&q=80',
    description: 'Chunky knit cardigan with wooden buttons and drop shoulders.',
    sizes: <String>['S', 'M', 'L'],
  ),
  Product(
    id: 'p3',
    name: 'Indigo Denim Jacket',
    category: 'Denim',
    price: 3200,
    stock: 5,
    barcode: '6290100000037',
    imageUrl:
        'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=600&q=80',
    description: 'Rigid indigo denim jacket that fades beautifully with wear.',
    sizes: <String>['S', 'M', 'L', 'XL'],
  ),
  Product(
    id: 'p4',
    name: 'Pleated Midi Dress',
    category: 'Dresses',
    price: 2750,
    stock: 9,
    barcode: '6290100000044',
    imageUrl:
        'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=600&q=80',
    description: 'Flowing pleated midi dress with a matching waist tie.',
    sizes: <String>['XS', 'S', 'M', 'L'],
  ),
  Product(
    id: 'p5',
    name: 'Boxy Poplin Shirt',
    category: 'Tops',
    price: 1450,
    stock: 18,
    barcode: '6290100000051',
    imageUrl:
        'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&q=80',
    description: 'Crisp cotton poplin shirt with a modern boxy silhouette.',
    sizes: <String>['S', 'M', 'L', 'XL'],
  ),
  Product(
    id: 'p6',
    name: 'Wool Blend Scarf',
    category: 'Accessories',
    price: 950,
    stock: 3,
    barcode: '6290100000068',
    imageUrl:
        'https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=600&q=80',
    description: 'Loom-woven scarf in a warm herringbone weave.',
    sizes: <String>['One size'],
  ),
  Product(
    id: 'p7',
    name: 'Relaxed Linen Trousers',
    category: 'Bottoms',
    price: 1900,
    stock: 14,
    barcode: '6290100000075',
    imageUrl:
        'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=600&q=80',
    description: 'Breathable linen trousers with an elastic drawstring waist.',
    sizes: <String>['S', 'M', 'L', 'XL'],
  ),
  Product(
    id: 'p8',
    name: 'Leather Belt',
    category: 'Accessories',
    price: 1150,
    stock: 0,
    barcode: '6290100000082',
    imageUrl:
        'https://images.unsplash.com/photo-1624222247344-550fb60583dc?w=600&q=80',
    description: 'Full-grain leather belt with a solid brass buckle.',
    sizes: <String>['M', 'L'],
  ),
];

const List<String> sellerNames = <String>[
  'Hanna',
  'Samuel',
  'Liya',
  'Meron',
  'Dawit',
];

/// Deterministic demo sales so the dashboards look alive on first run.
List<Sale> generateSales({
  required DateTime day,
  required int count,
  required int seed,
}) {
  final Random rng = Random(seed);
  final List<Sale> sales = <Sale>[];
  for (int i = 0; i < count; i++) {
    final int hour = 9 + rng.nextInt(12); // 09:00 - 20:59
    final int minute = rng.nextInt(60);
    final int lineCount = 1 + rng.nextInt(3);
    final List<SaleLine> lines = <SaleLine>[];
    for (int j = 0; j < lineCount; j++) {
      final Product p = seedProducts[rng.nextInt(seedProducts.length)];
      lines.add(SaleLine(
        name: p.name,
        size: p.sizes[rng.nextInt(p.sizes.length)],
        qty: 1 + rng.nextInt(2),
        price: p.price,
      ));
    }
    final double total =
        lines.fold(0.0, (double s, SaleLine l) => s + l.lineTotal);
    final int roll = rng.nextInt(100);
    final PaymentMethod method = roll < 45
        ? PaymentMethod.cash
        : (roll < 75 ? PaymentMethod.card : PaymentMethod.mobile);
    sales.add(Sale(
      id: 'S${day.month}${day.day}${rng.nextInt(9000) + 1000}',
      lines: lines,
      total: total,
      method: method,
      time: DateTime(day.year, day.month, day.day, hour, minute),
      seller: sellerNames[rng.nextInt(sellerNames.length)],
    ));
  }
  sales.sort((Sale a, Sale b) => a.time.compareTo(b.time));
  return sales;
}

final List<Employee> seedEmployees = <Employee>[
  Employee(
      name: 'Hanna Girma',
      title: 'Senior Stylist',
      branch: 'Bole Flagship',
      shift: 'Mon - Fri · 9:00 - 17:00',
      todaySales: 6420),
  Employee(
      name: 'Samuel Bekele',
      title: 'Floor Lead',
      branch: 'Bole Flagship',
      shift: 'Mon - Sat · 12:00 - 20:00',
      todaySales: 5210),
  Employee(
      name: 'Liya Tadesse',
      title: 'Stylist',
      branch: 'Kazanchis',
      shift: 'Tue - Sat · 10:00 - 18:00',
      todaySales: 3980),
  Employee(
      name: 'Meron Alemu',
      title: 'Stylist',
      branch: 'Megenagna',
      shift: 'Wed - Sun · 9:00 - 17:00',
      todaySales: 2870),
  Employee(
      name: 'Dawit Kassa',
      title: 'Stock Associate',
      branch: 'Bole Flagship',
      shift: 'Mon - Fri · 8:00 - 16:00',
      todaySales: 1520),
];

final List<Branch> seedBranches = <Branch>[
  Branch(
      name: 'Bole Flagship',
      manager: 'Samuel Bekele',
      revenue: 18400,
      target: 25000,
      staff: 8),
  Branch(
      name: 'Kazanchis',
      manager: 'Liya Tadesse',
      revenue: 11250,
      target: 15000,
      staff: 5),
  Branch(
      name: 'Megenagna',
      manager: 'Meron Alemu',
      revenue: 8600,
      target: 12000,
      staff: 4),
];

final List<ShiftSlot> seedSchedule = <ShiftSlot>[
  ShiftSlot(day: 1, name: 'Hanna Girma', time: '9:00 - 17:00'),
  ShiftSlot(day: 1, name: 'Dawit Kassa', time: '8:00 - 16:00'),
  ShiftSlot(day: 2, name: 'Samuel Bekele', time: '12:00 - 20:00'),
  ShiftSlot(day: 2, name: 'Liya Tadesse', time: '10:00 - 18:00'),
  ShiftSlot(day: 3, name: 'Hanna Girma', time: '9:00 - 17:00'),
  ShiftSlot(day: 3, name: 'Meron Alemu', time: '9:00 - 17:00'),
  ShiftSlot(day: 4, name: 'Samuel Bekele', time: '12:00 - 20:00'),
  ShiftSlot(day: 4, name: 'Dawit Kassa', time: '8:00 - 16:00'),
  ShiftSlot(day: 5, name: 'Liya Tadesse', time: '10:00 - 18:00'),
  ShiftSlot(day: 5, name: 'Hanna Girma', time: '9:00 - 17:00'),
  ShiftSlot(day: 6, name: 'Meron Alemu', time: '11:00 - 19:00'),
  ShiftSlot(day: 6, name: 'Samuel Bekele', time: '12:00 - 20:00'),
  ShiftSlot(day: 7, name: 'Liya Tadesse', time: '11:00 - 19:00'),
];
