import 'dart:math';

import 'package:flutter/material.dart';

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
    tag: 'Best seller',
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
    tag: 'New in',
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
    tag: 'New in',
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
      id: 'e1',
      name: 'Hanna Girma',
      title: 'Senior Stylist',
      branch: 'Bole Flagship',
      shift: 'Mon - Fri · 9:00 - 17:00',
      todaySales: 6420,
      orders: 22,
      conversion: 34,
      phone: '+251 911 234 567'),
  Employee(
      id: 'e2',
      name: 'Samuel Bekele',
      title: 'Floor Lead',
      branch: 'Bole Flagship',
      shift: 'Mon - Sat · 12:00 - 20:00',
      todaySales: 5210,
      orders: 16,
      conversion: 28,
      phone: '+251 911 345 678'),
  Employee(
      id: 'e3',
      name: 'Liya Tadesse',
      title: 'Stylist',
      branch: 'Kazanchis',
      shift: 'Tue - Sat · 10:00 - 18:00',
      todaySales: 3980,
      orders: 12,
      conversion: 31,
      phone: '+251 911 456 789'),
  Employee(
      id: 'e4',
      name: 'Meron Alemu',
      title: 'Stylist',
      branch: 'Megenagna',
      shift: 'Wed - Sun · 9:00 - 17:00',
      todaySales: 2870,
      orders: 9,
      conversion: 24,
      phone: '+251 911 567 890',
      status: EmployeeStatus.onLeave),
  Employee(
      id: 'e5',
      name: 'Dawit Kassa',
      title: 'Stock Associate',
      branch: 'Bole Flagship',
      shift: 'Mon - Fri · 8:00 - 16:00',
      todaySales: 1520,
      orders: 5,
      conversion: 18,
      phone: '+251 911 678 901'),
];

/// Inter-location movements for the manager transfer queue.
final List<TransferOrder> seedTransfers = <TransferOrder>[
  TransferOrder(
    id: 'TR-208',
    productName: 'Knit Cardigan',
    qty: 4,
    from: 'Bole Flagship',
    to: 'Kazanchis',
  ),
  TransferOrder(
    id: 'TR-207',
    productName: 'Wool Blend Scarf',
    qty: 6,
    from: 'Megenagna',
    to: 'Bole Flagship',
    inTransit: false,
  ),
];

final List<OpsItem> seedApprovals = <OpsItem>[
  OpsItem(
    title: '25% discount override',
    subtitle: 'Hanna Girma · Pleated Midi Dress · 2 items',
    meta: '2h ago',
    icon: Icons.sell_outlined,
  ),
  OpsItem(
    title: 'Price change ETB 1,450 → 1,290',
    subtitle: 'Boxy Poplin Shirt · weekend promo',
    meta: '3h ago',
    icon: Icons.price_change_outlined,
  ),
  OpsItem(
    title: 'Restock request · 20 units',
    subtitle: 'Leather Belt · Megenagna',
    meta: '5h ago',
    icon: Icons.inventory_outlined,
  ),
  OpsItem(
    title: 'Time-off request',
    subtitle: 'Liya Tadesse · next Saturday',
    meta: 'Yesterday',
    icon: Icons.event_busy_outlined,
  ),
];

final List<OpsItem> seedAuditLog = <OpsItem>[
  OpsItem(
    title: 'Register 1 opened',
    subtitle: 'Samuel Bekele · opening float ETB 2,000',
    meta: '09:02',
    icon: Icons.point_of_sale,
  ),
  OpsItem(
    title: 'Stock adjusted +6',
    subtitle: 'Dawit Kassa · Knit Cardigan (delivery received)',
    meta: '09:40',
    icon: Icons.inventory_2_outlined,
  ),
  OpsItem(
    title: 'Price edited',
    subtitle: 'Meron Alemu · Wool Blend Scarf ETB 950 → 1,050',
    meta: '11:15',
    icon: Icons.edit_outlined,
  ),
  OpsItem(
    title: 'Discount applied 10%',
    subtitle: 'Hanna Girma · sale S10481',
    meta: '12:48',
    icon: Icons.sell_outlined,
  ),
  OpsItem(
    title: 'Transfer TR-208 created',
    subtitle: 'Samuel Bekele · 4 × Knit Cardigan → Kazanchis',
    meta: '13:20',
    icon: Icons.local_shipping_outlined,
  ),
  OpsItem(
    title: 'Role switched to manager',
    subtitle: 'Hanna Girma',
    meta: '14:05',
    icon: Icons.switch_account_outlined,
  ),
];

final List<OpsItem> seedCatalogUpdates = <OpsItem>[
  OpsItem(
      title: 'Price sync pending',
      subtitle: 'Boxy Poplin Shirt · ETB 1,450 → 1,390',
      meta: 'Pricing',
      icon: Icons.price_change_outlined),
  OpsItem(
      title: 'Photo refresh',
      subtitle: 'Pleated Midi Dress · new hero image',
      meta: 'Media',
      icon: Icons.image_outlined),
  OpsItem(
      title: 'Description update',
      subtitle: 'Knit Cardigan · copy rewrite',
      meta: 'Copy',
      icon: Icons.notes),
  OpsItem(
      title: 'Category change',
      subtitle: 'Leather Belt · Accessories → Footwear care',
      meta: 'Taxonomy',
      icon: Icons.category_outlined),
  OpsItem(
      title: 'Barcode re-assigned',
      subtitle: 'Wool Blend Scarf · 6290100000068',
      meta: 'Identity',
      icon: Icons.qr_code_2),
  OpsItem(
      title: 'Size run added',
      subtitle: 'Relaxed Linen Trousers · XXL added',
      meta: 'Variants',
      icon: Icons.checkroom),
];

final List<OpsItem> seedAlerts = <OpsItem>[
  OpsItem(
      title: 'Leather Belt is out of stock',
      subtitle: 'Bole Flagship · missed for 6 hours',
      meta: 'Stock',
      icon: Icons.error_outline),
  OpsItem(
      title: '3 styles running low',
      subtitle: 'Wool Blend Scarf · Indigo Denim Jacket · 1 more',
      meta: 'Stock',
      icon: Icons.warning_amber_outlined),
  OpsItem(
      title: 'Approvals waiting',
      subtitle: '4 requests need a decision today',
      meta: 'Team',
      icon: Icons.how_to_reg_outlined),
  OpsItem(
      title: 'Register 1 not closed',
      subtitle: 'Yesterday close was skipped · reconcile now',
      meta: 'Cash',
      icon: Icons.point_of_sale),
  OpsItem(
      title: 'Sync queue backlog',
      subtitle: '2 offline sales waiting to upload',
      meta: 'System',
      icon: Icons.cloud_sync_outlined),
  OpsItem(
      title: 'Conversion dipped at Megenagna',
      subtitle: '24% vs 31% branch average',
      meta: 'Team',
      icon: Icons.trending_down),
  OpsItem(
      title: 'New seller first shift',
      subtitle: 'Dawit Kassa · schedule published',
      meta: 'Team',
      icon: Icons.badge_outlined),
  OpsItem(
      title: 'Promo weekend starts Friday',
      subtitle: '6 catalog updates pending approval',
      meta: 'Catalog',
      icon: Icons.campaign_outlined),
];

final List<OpsItem> seedOfflineQueue = <OpsItem>[
  OpsItem(
      title: 'Sale S10477 · ETB 2,340',
      subtitle: 'Card payment · taken offline at 16:12',
      meta: 'Queued',
      icon: Icons.receipt_long),
  OpsItem(
      title: 'Stock count · 41 items',
      subtitle: 'Dawit Kassa · back room recount',
      meta: 'Queued',
      icon: Icons.fact_check_outlined),
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

/// Recent spending entries for the Expenses module.
final List<Expense> seedExpenses = <Expense>[
  Expense(
    id: 'x1',
    title: 'December store rent',
    category: 'Rent',
    amount: 18000,
    time: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
    branch: 'Bole Flagship',
    note: 'Paid via CBE transfer',
    recordedBy: 'manager',
  ),
  Expense(
    id: 'x2',
    title: 'Staff salaries · last month',
    category: 'Salaries',
    amount: 42000,
    time: DateTime.now().subtract(const Duration(days: 4)),
    branch: 'Bole Flagship',
    recordedBy: 'manager',
  ),
  Expense(
    id: 'x3',
    title: 'Window display mannequins',
    category: 'Supplies',
    amount: 3600,
    time: DateTime.now().subtract(const Duration(hours: 7)),
    branch: 'Kazanchis',
    note: '2x torso mannequin + stand',
    recordedBy: 'manager',
  ),
  Expense(
    id: 'x4',
    title: 'Electricity bill',
    category: 'Utilities',
    amount: 1450,
    time: DateTime.now().subtract(const Duration(hours: 26)),
    branch: 'Megenagna',
    recordedBy: 'manager',
  ),
  Expense(
    id: 'x5',
    title: 'Instagram promo shoot',
    category: 'Marketing',
    amount: 2800,
    time: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
    branch: 'Bole Flagship',
    note: 'Photographer + 2 models',
    recordedBy: 'manager',
  ),
  Expense(
    id: 'x6',
    title: 'Fitting-room curtain repair',
    category: 'Maintenance',
    amount: 480,
    time: DateTime.now().subtract(const Duration(days: 6)),
    branch: 'Kazanchis',
    recordedBy: 'manager',
  ),
];

/// Non-sale income entries for the Income module.
final List<IncomeEntry> seedIncomes = <IncomeEntry>[
  IncomeEntry(
    id: 'i1',
    title: 'Bridal party alterations',
    source: 'Alterations',
    amount: 1650,
    time: DateTime.now().subtract(const Duration(hours: 4)),
    branch: 'Bole Flagship',
    recordedBy: 'hanna',
  ),
  IncomeEntry(
    id: 'i2',
    title: 'Consignment payout · Selam Handbags',
    source: 'Consignment',
    amount: 5200,
    time: DateTime.now().subtract(const Duration(days: 3)),
    branch: 'Bole Flagship',
    recordedBy: 'manager',
  ),
  IncomeEntry(
    id: 'i3',
    title: 'Bulk order · Zemen Hotel uniforms',
    source: 'Wholesale',
    amount: 12600,
    time: DateTime.now().subtract(const Duration(days: 5, hours: 2)),
    branch: 'Kazanchis',
    recordedBy: 'manager',
  ),
];

/// Archived Z report shown in the close-of-day history.
final List<ShiftReport> seedReports = <ShiftReport>[
  ShiftReport(
    id: 'Z-118',
    type: 'Z',
    time: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
    register: 'Register 1 · Bole Flagship',
    cashier: 'Samuel Bekele',
    transactions: 27,
    itemsSold: 41,
    grossSales: 19820,
    discounts: 640,
    netSales: 19180,
    cash: 8630,
    card: 7210,
    mobile: 3340,
    openingFloat: 2000,
    countedCash: 10610,
    variance: -20,
    note: 'Short 20 — rounding on two cash refunds',
  ),
  ShiftReport(
    id: 'Z-117',
    type: 'Z',
    time: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
    register: 'Register 1 · Bole Flagship',
    cashier: 'Hanna Girma',
    transactions: 31,
    itemsSold: 47,
    grossSales: 22430,
    discounts: 980,
    netSales: 21450,
    cash: 10120,
    card: 7830,
    mobile: 3500,
    openingFloat: 2000,
    countedCash: 12120,
    variance: 0,
    note: 'Clean close',
  ),
];
