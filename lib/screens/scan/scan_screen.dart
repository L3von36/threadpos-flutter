import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../add/add_product_screen.dart';

/// Barcode scanning tab. Uses the camera via mobile_scanner when
/// available and always offers a manual barcode entry fallback.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.active = false});

  /// True while this tab is selected; the camera only runs when active.
  final bool active;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final TextEditingController _manual = TextEditingController();
  bool _lock = false;

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_lock || !mounted) return;
    for (final Barcode bar in capture.barcodes) {
      final String? code = bar.rawValue;
      if (code == null || code.isEmpty) continue;
      _lock = true;
      _handleCode(code);
      return;
    }
  }

  void _handleCode(String code) {
    final Store store = context.read<Store>();
    final Product? product =
        store.findByBarcode(code) ?? store.findByName(code);
    if (!mounted) return;
    if (product != null) {
      _showFound(product);
    } else {
      _showNotFound(code);
    }
  }

  Future<void> _showFound(Product product) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: productImage(product.imageUrl),
              ),
            ),
            const SizedBox(height: 14),
            Text(product.name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink)),
            const SizedBox(height: 4),
            Text('${product.category} · ${product.stockLabel} · ${product.barcode}',
                style: const TextStyle(
                    fontSize: 12.5, color: AppTheme.muted)),
            const SizedBox(height: 6),
            Text(money(product.price),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.terracotta)),
            const SizedBox(height: 16),
            FilledButton(
              style: AppTheme.primaryButton,
              onPressed: product.isOutOfStock
                  ? null
                  : () {
                      context.read<Store>().addToCart(
                            product,
                            size: product.sizes.isNotEmpty
                                ? product.sizes.first
                                : '',
                          );
                      Navigator.of(sheetContext).pop();
                      showSnack(sheetContext,
                          '${product.name} added to cart');
                    },
              child: Text(product.isOutOfStock
                  ? 'Out of stock'
                  : 'Add to cart'),
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(() => _lock = false);
  }

  Future<void> _showNotFound(String code) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('No match'),
        content: Text(
            'No product found for "$code". Add it to the catalog now?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not now',
                style: TextStyle(color: AppTheme.muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AddProductScreen(initialBarcode: code.trim()),
                ),
              );
            },
            child: const Text('Add product'),
          ),
        ],
      ),
    );
    if (mounted) setState(() => _lock = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan barcode')),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    if (widget.active)
                      _ScannerArea(onDetect: _onDetect)
                    else
                      const ColoredBox(
                        color: AppTheme.ink,
                        child: Center(
                          child: Text('Camera idle',
                              style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(
                    controller: _manual,
                    onSubmitted: _handleCode,
                    textInputAction: TextInputAction.go,
                    decoration: AppTheme.input('Enter barcode or name',
                        icon: Icons.dialpad),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.terracotta,
                      minimumSize: const Size.fromHeight(46),
                      side: const BorderSide(color: AppTheme.terracotta),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _handleCode(_manual.text),
                    child: const Text('Find product',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boots the camera in a try/catch so the app degrades gracefully on
/// emulators and devices without a camera.
class _ScannerArea extends StatefulWidget {
  const _ScannerArea({required this.onDetect});

  final ValueChanged<BarcodeCapture> onDetect;

  @override
  State<_ScannerArea> createState() => _ScannerAreaState();
}

class _ScannerAreaState extends State<_ScannerArea> {
  MobileScannerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final MobileScannerController controller =
        MobileScannerController(autoStart: false);
    try {
      await controller.start();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const ColoredBox(
        color: AppTheme.ink,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.videocam_off_outlined,
                  color: Colors.white54, size: 34),
              SizedBox(height: 10),
              Text('Camera not available here',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              SizedBox(height: 4),
              Text('Use manual entry below to find products.',
                  style: TextStyle(color: Colors.white38, fontSize: 11.5)),
            ],
          ),
        ),
      );
    }
    final MobileScannerController? controller = _controller;
    if (controller == null) {
      return const ColoredBox(
        color: AppTheme.ink,
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white70),
          ),
        ),
      );
    }
    return MobileScanner(
      controller: controller,
      onDetect: widget.onDetect,
    );
  }
}
