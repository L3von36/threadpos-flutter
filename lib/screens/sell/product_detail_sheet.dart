import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// Bottom sheet with product details, size picker and add-to-cart.
Future<void> showProductDetailSheet(
    BuildContext context, Product product) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (BuildContext sheetContext) =>
        _ProductDetailSheet(product: product),
  );
}

class _ProductDetailSheet extends StatefulWidget {
  const _ProductDetailSheet({required this.product});

  final Product product;

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  late String _size;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _size = widget.product.sizes.isNotEmpty ? widget.product.sizes.first : '';
  }

  @override
  Widget build(BuildContext context) {
    final Product product = widget.product;
    final double maxH = MediaQuery.of(context).size.height * 0.9;
    return SingleChildScrollView(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Stack(
              children: <Widget>[
                SizedBox(
                  height: 210,
                  width: double.infinity,
                  child: productImage(product.imageUrl),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 18, color: AppTheme.ink),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(product.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink)),
                      ),
                      Text(money(product.price),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.terracotta)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.creamDeep,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(product.category,
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.ink)),
                      ),
                      const SizedBox(width: 10),
                      Text(product.stockLabel,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppTheme.muted)),
                    ],
                  ),
                  if (product.description.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 14),
                    Text(product.description,
                        style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: AppTheme.muted)),
                  ],
                  if (product.sizes.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 18),
                    const Text('Size',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.sizes
                          .map((String s) => ChoiceChip(
                                label: Text(s),
                                selected: s == _size,
                                onSelected: (bool _) =>
                                    setState(() => _size = s),
                                selectedColor: AppTheme.terracotta,
                                backgroundColor: Colors.white,
                                showCheckmark: false,
                                labelStyle: TextStyle(
                                    color: s == _size
                                        ? Colors.white
                                        : AppTheme.ink,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(999),
                                  side: const BorderSide(
                                      color: AppTheme.border),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text('Quantity',
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink)),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: _qty > 1
                                  ? () => setState(() => _qty--)
                                  : null,
                            ),
                            Text('$_qty',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () =>
                                  setState(() => _qty++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    style: AppTheme.primaryButton,
                    onPressed: product.isOutOfStock
                        ? null
                        : () {
                            context.read<Store>().addToCart(product,
                                size: _size, qty: _qty);
                            Navigator.of(context).pop();
                            showSnack(context,
                                '${product.name} added to cart');
                          },
                    child: Text(product.isOutOfStock
                        ? 'Out of stock'
                        : 'Add to cart · ${money(product.price * _qty)}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
