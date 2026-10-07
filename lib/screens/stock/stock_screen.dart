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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: StatCard(
                    label: 'Styles',
                    value: '${store.products.length}',
                    icon: Icons.checkroom,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Units in stock',
                    value: '${store.totalUnits}',
                    icon: Icons.inventory_2_outlined,
                    color: AppTheme.sage,
                  ),
                ),
                const SizedBox(width: 10),
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
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: <String>['All', 'Low', 'Out']
                  .map((String f) => Padding(
                        padding: const EdgeInsets.only(right: 8, top: 12),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: _filter == f,
                          onSelected: (bool _) =>
                              setState(() => _filter = f),
                          selectedColor: AppTheme.terracotta,
                          backgroundColor: Colors.white,
                          showCheckmark: false,
                          labelStyle: TextStyle(
                              color: _filter == f
                                  ? Colors.white
                                  : AppTheme.ink,
                              fontSize: 12.5,
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int i) {
                      final Product p = items[i];
                      final Color badgeColor = p.isOutOfStock
                          ? AppTheme.danger
                          : (p.isLowStock
                              ? AppTheme.amber
                              : AppTheme.sage);
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 54,
                                height: 54,
                                child: productImage(p.imageUrl),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppTheme.ink)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: <Widget>[
                                      StockBadge(
                                        label: p.stockLabel,
                                        color: badgeColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(p.category,
                                          style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppTheme.muted)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Restock',
                              icon: const Icon(
                                  Icons.add_box_outlined,
                                  size: 20,
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
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Restock ${product.name}'),
        content: TextField(
          controller: qty,
          keyboardType: TextInputType.number,
          autofocus: true,
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
