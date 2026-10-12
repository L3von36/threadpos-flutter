import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/offline_badge.dart';
import '../../widgets/motion.dart';
import 'cart_screen.dart';
import 'pos_camera_scanner.dart';
import 'product_detail_sheet.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  String _query = '';
  String _category = 'All';
  late final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openBarcodeScanner() {
    showPosBarcodeScanner(
      context,
      onProductFound: (Product product) {
        showProductDetailSheet(context, product);
      },
    );
  }

  String _greeting() {
    final int h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static const List<String> _weekday = <String>[
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final List<String> categories = <String>[
      'All',
      ...store.products.map((Product p) => p.category).toSet(),
    ];
    final List<Product> items = store.products.where((Product p) {
      final bool matchesCategory =
          _category == 'All' || p.category == _category;
      final bool matchesQuery = _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
          p.barcode.contains(_query);
      return matchesCategory && matchesQuery;
    }).toList();

    final DateTime now = DateTime.now();
    final String shiftChip =
        'Floor shift · ${_weekday[now.weekday - 1]}, $now.${now.month}';

    return Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              // Seller shift & quick scanner strip
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: pal.surface,
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                  border: Border.all(color: pal.border),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: pal.accent.withValues(alpha: 0.14),
                      child: Text(
                        store.displayName.isEmpty
                            ? '?'
                            : store.displayName[0].toUpperCase(),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: pal.accent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('${_greeting()}, ${store.displayName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: pal.ink)),
                          Text(shiftChip,
                              style: TextStyle(
                                  fontSize: 10, color: pal.muted)),
                        ],
                      ),
                    ),
                    PressableScale(
                      onTap: _openBarcodeScanner,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: pal.softAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.qr_code_scanner_rounded, size: 14, color: pal.accent),
                            const SizedBox(width: 4),
                            Text('Scan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pal.accent)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (store.isOffline)
                GestureDetector(
                  onTap: () => showOfflineSheet(context, store),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: pal.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.rSm),
                    border: Border.all(
                        color: pal.warning.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.cloud_off_rounded,
                          size: 14, color: pal.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          store.pendingOfflineCount == 0
                              ? 'Offline Mode (Internet Outage) · Hive Local Storage Active'
                              : 'Offline Mode · ${store.pendingOfflineCount} transaction(s) queued for sync',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: pal.warning,
                          ),
                        ),
                      ),
                      PressableScale(
                        onTap: () {
                          store.syncNow();
                        },
                        child: Text(
                          'Sync',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: pal.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (String v) => setState(() => _query = v),
                        style: TextStyle(fontSize: 13, color: pal.ink),
                        decoration: AppTheme.input(
                          context,
                          'Search pieces, SKU, or barcode',
                          icon: Icons.search,
                          suffix: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: pal.accent,
                      borderRadius: BorderRadius.circular(AppTheme.rMd),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppTheme.rMd),
                        onTap: _openBarcodeScanner,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(Icons.qr_code_scanner_rounded,
                                  size: 18, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Scan',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (BuildContext context, int i) {
                    final String c = categories[i];
                    final bool selected = c == _category;
                    return ChoiceChip(
                      label: Text(c),
                      selected: selected,
                      onSelected: (bool _) => setState(() => _category = c),
                      selectedColor: pal.accent,
                      backgroundColor: pal.surface,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                          color: selected ? Colors.white : pal.ink,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(color: pal.border),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: 'No products found',
                        subtitle:
                            'Try a different search or category filter.')
                    : GridView.builder(
                        // Extra bottom padding so the floating sale bar
                        // never covers the last row of cards.
                        padding:
                            const EdgeInsets.fromLTRB(12, 8, 12, 96),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: items.length,
                        itemBuilder: (BuildContext context, int i) =>
                            StaggerIn(
                          index: i,
                          child: PressableScale(
                            onTap: () =>
                                showProductDetailSheet(context, items[i]),
                            pressedScale: 0.95,
                            child: _ProductCard(product: items[i]),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          // Floating "Start a new sale" bar (empty-cart state, like the
          // reference). Once items exist the shell's View-sale pill
          // takes over, so we only render this when the cart is empty.
          Positioned(
            left: 14,
            right: 14,
            bottom: 10,
            child: IgnorePointer(
              ignoring: store.cartCount > 0,
              child: AnimatedSlide(
                duration: Motion.slow,
                curve: Motion.out,
                offset: store.cartCount > 0
                    ? const Offset(0, 1.6)
                    : Offset.zero,
                child: AnimatedOpacity(
                  duration: Motion.base,
                  opacity: store.cartCount > 0 ? 0 : 1,
                  child: PressableScale(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const CartScreen()),
                    ),
                    pressedScale: 0.97,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 10),
                      decoration: BoxDecoration(
                        color: pal.bannerBg,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.shopping_bag_outlined,
                              size: 17, color: pal.bannerText),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Start a new sale',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.1,
                                        fontWeight: FontWeight.w700,
                                        color: pal.bannerText)),
                                Text('Tap a piece to add it',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: pal.bannerSub)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_rounded,
                              size: 16, color: pal.bannerSub),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  void _quickAdd(BuildContext context) {
    final Store store = context.read<Store>();
    if (product.isOutOfStock) {
      showSnack(context, '${product.name} is out of stock');
      return;
    }
    store.addToCart(product,
        size: product.sizes.isNotEmpty ? product.sizes.first : '');
    showAddedToast(context, product.name);
  }

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);

    // One badge per card: stock state wins, else the merchandising tag.
    String? badge;
    Color? badgeColor;
    if (product.isOutOfStock) {
      badge = 'Out';
      badgeColor = pal.danger;
    } else if (product.isLowStock) {
      badge = 'Low stock';
      badgeColor = pal.amber;
    } else if (product.isBestSeller) {
      badge = 'Best seller';
      badgeColor = pal.amber;
    } else if (product.isNew) {
      badge = 'New in';
      badgeColor = pal.accent;
    }

    return Container(
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        border: Border.all(color: pal.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.rMd)),
                  child: productImage(context, product.imageUrl),
                ),
                if (badge != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: StockBadge(label: badge, color: badgeColor!),
                  ),
                // Quick-add button, bottom-right over the photo.
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _quickAdd(context),
                    child: AnimatedContainer(
                      duration: Motion.press,
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: product.isOutOfStock
                            ? pal.muted.withValues(alpha: 0.55)
                            : pal.bannerBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_rounded,
                          size: 17, color: pal.bannerText),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        height: 1.15,
                        color: pal.ink)),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(money(product.price),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: pal.accent)),
                    Text(product.stockLabel,
                        style: TextStyle(
                            fontSize: 10, color: pal.muted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
