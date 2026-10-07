import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

const List<String> _categories = <String>[
  'Tops',
  'Dresses',
  'Outerwear',
  'Denim',
  'Bottoms',
  'Accessories',
  'Footwear',
];

/// New product intake form with barcode assignment.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key, this.initialBarcode});

  /// Pre-filled when arriving from a failed barcode scan.
  final String? initialBarcode;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _stock = TextEditingController();
  final TextEditingController _barcode = TextEditingController();
  final TextEditingController _imageUrl = TextEditingController();
  final TextEditingController _description = TextEditingController();
  String _category = _categories.first;

  @override
  void initState() {
    super.initState();
    _barcode.text = widget.initialBarcode ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _barcode.dispose();
    _imageUrl.dispose();
    _description.dispose();
    super.dispose();
  }

  void _generateBarcode() {
    final Random rng = Random();
    final StringBuffer code = StringBuffer('629'); // Ethiopia EAN prefix
    for (int i = 0; i < 10; i++) {
      code.write(rng.nextInt(10));
    }
    setState(() => _barcode.text = code.toString());
  }

  void _save() {
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    final Product product = Product(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category,
      price: double.tryParse(_price.text.trim()) ?? 0,
      stock: int.tryParse(_stock.text.trim()) ?? 0,
      barcode: _barcode.text.trim(),
      imageUrl: _imageUrl.text.trim(),
      description: _description.text.trim(),
    );
    context.read<Store>().addProduct(product);
    showSnack(context, '${product.name} added to inventory');
    final bool pushed = Navigator.of(context).canPop();
    if (pushed) {
      Navigator.of(context).pop();
    } else {
      _formKey.currentState?.reset();
      _name.clear();
      _price.clear();
      _stock.clear();
      _barcode.clear();
      _imageUrl.clear();
      _description.clear();
      setState(() => _category = _categories.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: <Widget>[
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: AppTheme.input(context, 'Product name',
                  icon: Icons.checkroom),
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Enter a product name'
                      : null,
            ),
            const SizedBox(height: 11),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: AppTheme.input(context, 'Category',
                  icon: Icons.category_outlined),
              items: _categories
                  .map((String c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (String? v) =>
                  setState(() => _category = v ?? _categories.first),
            ),
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: AppTheme.input(context, 'Price (ETB)',
                        icon: Icons.sell_outlined),
                    validator: (String? v) {
                      final double? p = double.tryParse(v ?? '');
                      if (p == null || p <= 0) {
                        return 'Enter a valid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: AppTheme.input(context, 'Stock qty',
                        icon: Icons.inventory_2_outlined),
                    validator: (String? v) {
                      final int? s = int.tryParse(v ?? '');
                      if (s == null || s < 0) {
                        return 'Enter stock';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            TextFormField(
              controller: _barcode,
              keyboardType: TextInputType.number,
              decoration: AppTheme.input(context, 'Barcode',
                      icon: Icons.qr_code_2,
                      hint: 'Scan or generate a code')
                  .copyWith(
                suffixIcon: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.auto_awesome,
                      size: 18, color: pal.accent),
                  tooltip: 'Generate barcode',
                  onPressed: _generateBarcode,
                ),
              ),
              validator: (String? v) =>
                  (v == null || v.trim().length < 6)
                      ? 'Barcode needs at least 6 digits'
                      : null,
            ),
            const SizedBox(height: 11),
            TextFormField(
              controller: _imageUrl,
              keyboardType: TextInputType.url,
              decoration: AppTheme.input(context, 'Image URL (optional)',
                  icon: Icons.image_outlined,
                  hint: 'Leave blank for a styled placeholder'),
            ),
            const SizedBox(height: 11),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: AppTheme.input(context, 'Description (optional)',
                  icon: Icons.notes),
            ),
            const SizedBox(height: 18),
            PressableScale(
              child: FilledButton(
                style: AppTheme.primaryButton(context),
                onPressed: _save,
                child: const Text('Save to inventory'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saved products are stored on this device and appear '
              'immediately in the Sell grid and Stock list.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: pal.muted),
            ),
          ],
        ),
      ),
    );
  }
}
