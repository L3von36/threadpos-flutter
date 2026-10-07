import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

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
    final Pal pal = Pal.of(context);
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
                  child: StaggerIn(
                    index: 0,
                    dy: 8,
                    child: StatCard(
                      label: 'Styles',
                      value: '${store.products.length}',
                      icon: Icons.checkroom,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StaggerIn(
                    index: 1,
                    dy: 8,
                    child: StatCard(
                      label: 'Units in stock',
                      value: '${store.totalUnits}',
                      icon: Icons.inventory_2_outlined,
                      color: pal.sage,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StaggerIn(
                    index: 2,
                    dy: 8,
                    child: StatCard(
                      label: 'Needs restock',
                      value: '${store.lowStockProducts.length}',
                      icon: Icons.warning_amber_outlined,
                      color: pal.amber,
                    ),
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
                          selectedColor: pal.accent,
                          backgroundColor: pal.surface,
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(
                              color: _filter == f
                                  ? Colors.white
                                  : pal.ink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(color: pal.border),
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
                          ? pal.danger
                          : (p.isLowStock ? pal.amber : pal.sage);
                      return StaggerIn(
                        index: i,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: pal.surface,
                            borderRadius:
                                BorderRadius.circular(AppTheme.rMd),
                            border: Border.all(color: pal.border),
                          ),
                          child: Row(
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: SizedBox(
                                  width: 46,
                                  height: 46,
                                  child: productImage(context, p.imageUrl),
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
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: pal.ink)),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: <Widget>[
                                        StockBadge(
                                          label: p.stockLabel,
                                          color: badgeColor,
                                        ),
                                        const SizedBox(width: 7),
                                        Text(p.category,
                                            style: TextStyle(
                                                fontSize: 10.5,
                                                color: pal.muted)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PressableScale(
                                pressedScale: 0.82,
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Restock',
                                  icon: Icon(
                                      Icons.add_box_outlined,
                                      size: 19,
                                      color: pal.accent),
                                  onPressed: () =>
                                      _showRestockDialog(context, p),
                                ),
                              ),
                            ],
                          ),
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
        title: Text('Restock ${product.name}'),
        content: TextField(
          controller: qty,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: TextStyle(
              fontSize: 13, color: Pal.of(dialogContext).ink),
          decoration: AppTheme.input(dialogContext, 'Units to add',
              hint: 'Current: ${product.stock}'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel',
                style: TextStyle(color: Pal.of(dialogContext).muted)),
          ),
          PressableScale(
            child: FilledButton(
              onPressed: () {
                final int? amount = int.tryParse(qty.text.trim());
                if (amount != null && amount != 0) {
                  context.read<Store>().adjustStock(product.id, amount);
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Add stock'),
            ),
          ),
        ],
      ),
    );
    qty.dispose();
  }
}
