import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'cart_screen.dart';
import 'product_detail_sheet.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  String _query = '';
  String _category = 'All';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell'),
        actions: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const CartScreen()),
                ),
              ),
              if (store.cartCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: BumpOnChange(
                    trigger: store.cartCount,
                    amount: 0.3,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: pal.accent, shape: BoxShape.circle),
                      child: Text('${store.cartCount}',
                          style: TextStyle(
                              color: pal.toastText,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TextField(
              onChanged: (String v) => setState(() => _query = v),
              style: TextStyle(fontSize: 13, color: pal.ink),
              decoration: AppTheme.input(context, 'Search name or barcode',
                  icon: Icons.search),
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
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
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
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    final Color stockColor = product.isOutOfStock
        ? pal.danger
        : (product.isLowStock ? pal.amber : pal.sage);
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
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.rMd)),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  productImage(context, product.imageUrl),
                  if (product.isOutOfStock || product.isLowStock)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: StockBadge(
                        label: product.isOutOfStock ? 'Out' : 'Low',
                        color: stockColor,
                      ),
                    ),
                ],
              ),
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
