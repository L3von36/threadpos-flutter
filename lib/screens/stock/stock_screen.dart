import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final List<Product> items = store.products.where((Product p) {
      switch (_filter) {
        case 'Low':
          return p.isLowStock;
        case 'Out':
          return p.isOutOfStock;
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Stock')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: StatCard(
                    label: 'Styles',
                    value: '${store.products.length}',
                    icon: Icons.checkroom,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Units in stock',
                    value: '${store.totalUnits}',
                    icon: Icons.inventory_2_outlined,
                    color: AppTheme.sage,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Needs restock',
                    value: '${store.lowStockProducts.length}',
                    icon: Icons.warning_amber_outlined,
                    color: AppTheme.amber,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: <String>['All', 'Low', 'Out']
                  .map((String f) => Padding(
                        padding: const EdgeInsets.only(right: 7, top: 10),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: _filter == f,
                          onSelected: (bool _) =>
                              setState(() => _filter = f),
                          selectedColor: AppTheme.terracotta,
                          backgroundColor: Colors.white,
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(
                              color: _filter == f
                                  ? Colors.white
                                  : AppTheme.ink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side:
                                const BorderSide(color: AppTheme.border),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    icon: Icons.inventory_outlined,
                    title: 'Nothing here',
                    subtitle:
                        'No products match this filter right now.')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int i) {
                      final Product p = items[i];
                      final Color badgeColor = p.isOutOfStock
                          ? AppTheme.danger
                          : (p.isLowStock
                              ? AppTheme.amber
                              : AppTheme.sage);
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppTheme.rMd),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: SizedBox(
                                width: 46,
                                height: 46,
                                child: productImage(p.imageUrl),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppTheme.ink)),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: <Widget>[
                                      StockBadge(
                                        label: p.stockLabel,
                                        color: badgeColor,
                                      ),
                                      const SizedBox(width: 7),
                                      Text(p.category,
                                          style: const TextStyle(
                                              fontSize: 10.5,
                                              color: AppTheme.muted)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Restock',
                              icon: const Icon(
                                  Icons.add_box_outlined,
                                  size: 19,
                                  color: AppTheme.terracotta),
                              onPressed: () =>
                                  _showRestockDialog(context, p),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRestockDialog(
      BuildContext context, Product product) async {
    final TextEditingController qty = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.rLg)),
        title: Text('Restock ${product.name}'),
        content: TextField(
          controller: qty,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(fontSize: 13),
          decoration: AppTheme.input('Units to add',
              hint: 'Current: ${product.stock}'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final int? amount = int.tryParse(qty.text.trim());
              if (amount != null && amount != 0) {
                context.read<Store>().adjustStock(product.id, amount);
              }
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Add stock'),
          ),
        ],
      ),
    );
    qty.dispose();
  }
}
