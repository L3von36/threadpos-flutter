import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

/// Bottom sheet with product details, size picker and add-to-cart.
/// Colors come from the themed bottom-sheet, so it follows dark mode.
Future<void> showProductDetailSheet(
    BuildContext context, Product product) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
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
    final Pal pal = Pal.of(context);
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
                  height: 176,
                  width: double.infinity,
                  child: productImage(context, product.imageUrl),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: PressableScale(
                    onTap: () => Navigator.of(context).pop(),
                    pressedScale: 0.85,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: pal.surface.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 15, color: pal.ink),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  StaggerIn(
                    index: 0,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(product.name,
                              style: TextStyle(
                                  fontSize: 16.5,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: pal.ink)),
                        ),
                        Text(money(product.price),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: pal.accent)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  StaggerIn(
                    index: 1,
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: pal.surfaceAlt,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(product.category,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: pal.ink)),
                        ),
                        const SizedBox(width: 8),
                        Text(product.floorLabel,
                            style: TextStyle(
                                fontSize: 11.5, color: product.isLowStock || product.isOutOfStock
                                    ? (product.isOutOfStock ? pal.danger : pal.amber)
                                    : pal.sage)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  // Barcode surfaced like the reference detail sheet.
                  StaggerIn(
                    index: 1,
                    dy: 6,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.qr_code_2, size: 14, color: pal.muted),
                        const SizedBox(width: 5),
                        Text('Barcode',
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: pal.muted)),
                        const Spacer(),
                        Text(product.barcode,
                            style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                                color: pal.ink)),
                      ],
                    ),
                  ),
                  if (product.description.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    StaggerIn(
                      index: 2,
                      child: Text(product.description,
                          style: TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              color: pal.muted)),
                    ),
                  ],
                  if (product.sizes.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 14),
                    StaggerIn(
                      index: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Size',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: pal.ink)),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: product.sizes
                                .map((String s) => ChoiceChip(
                                      label: Text(s),
                                      selected: s == _size,
                                      onSelected: (bool _) =>
                                          setState(() => _size = s),
                                      selectedColor: pal.accent,
                                      backgroundColor: pal.surface,
                                      showCheckmark: false,
                                      labelStyle: TextStyle(
                                          color: s == _size
                                              ? Colors.white
                                              : pal.ink,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        side: BorderSide(
                                            color: pal.border),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  StaggerIn(
                    index: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Quantity',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: pal.ink)),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: pal.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: <Widget>[
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: _qty > 1
                                    ? () => setState(() => _qty--)
                                    : null,
                              ),
                              BumpOnChange(
                                trigger: _qty,
                                amount: 0.28,
                                child: Text('$_qty',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                        color: pal.ink)),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: () =>
                                    setState(() => _qty++),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  StaggerIn(
                    index: 5,
                    child: PressableScale(
                      child: FilledButton(
                        style: AppTheme.primaryButton(context),
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
                    ),
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
