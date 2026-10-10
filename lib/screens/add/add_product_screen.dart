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

/// New product intake as a two-step wizard: details first, then
/// identification (barcode assign + preview) — with a "save another
/// piece" rapid-entry loop like the reference catalog setup.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key, this.initialBarcode});

  /// Pre-filled when arriving from a failed barcode scan.
  final String? initialBarcode;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final GlobalKey<FormState> _step1Key = GlobalKey<FormState>();
  final GlobalKey<FormState> _step2Key = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _stock = TextEditingController();
  final TextEditingController _barcode = TextEditingController();
  final TextEditingController _imageUrl = TextEditingController();
  final TextEditingController _description = TextEditingController();
  String _category = _categories.first;
  int _step = 1;
  bool _justSaved = false;
  String? _successMessage;

  bool get _asManager => context.read<Store>().isManager;

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

  void _continueToStep2() {
    final bool valid = _step1Key.currentState?.validate() ?? false;
    if (!valid) return;
    setState(() => _step = 2);
  }

  void _save() {
    final bool valid = _step2Key.currentState?.validate() ?? false;
    if (!valid) return;
    final Store store = context.read<Store>();
    final Product product = Product(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category,
      price: double.tryParse(_price.text.trim()) ?? 0,
      stock: int.tryParse(_stock.text.trim()) ?? 0,
      barcode: _barcode.text.trim(),
      imageUrl: _imageUrl.text.trim(),
      description: _description.text.trim(),
      tag: 'New in',
      status: store.isManager
          ? ProductStatus.approved
          : ProductStatus.pending,
      addedBy: store.email,
    );
    store.submitProduct(product);
    _successMessage = store.isManager
        ? '${product.name} added to the catalog'
        : '${product.name} sent for manager approval';
    final bool pushed = Navigator.of(context).canPop();
    if (pushed) {
      showSnack(context, _successMessage!);
      Navigator.of(context).pop();
      return;
    }
    // Rapid entry: keep the screen up for the next piece.
    setState(() {
      _justSaved = true;
      _name.clear();
      _price.clear();
      _stock.clear();
      _imageUrl.clear();
      _description.clear();
      _category = _categories.first;
      _step = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add clothing'),
        actions: <Widget>[
          // "1 of 2" progress pill, like the reference.
          AnimatedSwitcher(
            duration: Motion.base,
            switchInCurve: Motion.pop,
            transitionBuilder: (Widget child, Animation<double> anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Container(
              key: ValueKey<int>(_step),
              margin: const EdgeInsets.only(right: 14),
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: pal.softAccent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$_step of 2',
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: pal.accent)),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Thin animated progress bar under the app bar.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _step / 2),
            duration: Motion.slow,
            curve: Motion.out,
            builder: (BuildContext context, double t, _) =>
                LinearProgressIndicator(
              value: t,
              minHeight: 2.4,
              backgroundColor: pal.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(pal.accent),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: Motion.base,
              switchInCurve: Motion.out,
              switchOutCurve: Curves.easeIn,
              transitionBuilder:
                  (Widget child, Animation<double> anim) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0.03, 0),
                            end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                );
              },
              child: _step == 1
                  ? _buildStep1(context, pal)
                  : _buildStep2(context, pal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(BuildContext context, Pal pal) {
    return Form(
      key: _step1Key,
      child: ListView(
        key: const ValueKey<int>(1),
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          Text('Product details',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: pal.ink)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: AppTheme.input(context, 'Clothing name',
                icon: Icons.checkroom,
                hint: 'e.g. Ribbed Merino Cardigan'),
            validator: (String? v) =>
                (v == null || v.trim().isEmpty)
                    ? 'Enter a product name'
                    : null,
          ),
          const SizedBox(height: 11),
          Text('Category',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: pal.ink)),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _categories
                .map((String c) => ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (bool _) =>
                          setState(() => _category = c),
                      selectedColor: pal.accent,
                      backgroundColor: pal.surface,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      labelStyle: TextStyle(
                          color: _category == c
                              ? Colors.white
                              : pal.ink,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(color: pal.border),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: AppTheme.input(context, 'Retail price (ETB)',
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
                  decoration: AppTheme.input(context, 'Opening stock',
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
              onPressed: _continueToStep2,
              child: const Text('Continue to barcode'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context, Pal pal) {
    return Form(
      key: _step2Key,
      child: ListView(
        key: const ValueKey<int>(2),
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          if (_justSaved) ...<Widget>[
            StaggerIn(
              index: 0,
              dy: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  color: pal.sage.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                  border:
                      Border.all(color: pal.sage.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: <Widget>[
                    PopIn(
                      begin: 0.5,
                      duration: Motion.base,
                      child: Icon(Icons.check_circle_rounded,
                          size: 16, color: pal.sage),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          _successMessage ??
                              'Saved to the catalog — add another piece',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: pal.ink)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text('Identification',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: pal.ink)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _barcode,
            keyboardType: TextInputType.number,
            decoration: AppTheme.input(context, 'Assign a barcode',
                    icon: Icons.qr_code_2,
                    hint: 'Scan or generate a code')
                .copyWith(
              suffixIcon: PressableScale(
                pressedScale: 0.88,
                onTap: _generateBarcode,
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Icon(Icons.auto_awesome,
                      size: 18, color: pal.accent),
                ),
              ),
            ),
            validator: (String? v) =>
                (v == null || v.trim().length < 6)
                    ? 'Barcode needs at least 6 digits'
                    : null,
            onChanged: (String v) {
              // Rebuild so the live barcode preview tracks the field.
              setState(() {
                if (_justSaved && v.isNotEmpty) _justSaved = false;
              });
            },
          ),
          const SizedBox(height: 12),
          // Live barcode preview, like the reference assign card.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pal.surface,
              borderRadius: BorderRadius.circular(AppTheme.rMd),
              border: Border.all(color: pal.border),
            ),
            child: _barcode.text.isEmpty
                ? Column(
                    children: <Widget>[
                      Icon(Icons.qr_code_2,
                          size: 30, color: pal.muted),
                      const SizedBox(height: 6),
                      Text('Barcode preview appears here',
                          style: TextStyle(
                              fontSize: 11, color: pal.muted)),
                    ],
                  )
                : BarcodeView(value: _barcode.text, height: 46),
          ),
          const SizedBox(height: 18),
          PressableScale(
            child: FilledButton(
              style: AppTheme.primaryButton(context),
              onPressed: _save,
              child: Text(_justSaved
                  ? 'Save another piece'
                  : 'Add clothing to catalog'),
            ),
          ),
          const SizedBox(height: 8),
          PressableScale(
            child: TextButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('Back to details'),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _asManager
                ? 'Saved pieces appear immediately in the Sell grid, '
                    'Stock list and barcode lookup.'
                : 'Pieces land in the manager\'s approval queue first — '
                    'they join the catalog once approved.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: pal.muted),
          ),
        ],
      ),
    );
  }
}
