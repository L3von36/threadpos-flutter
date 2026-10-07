import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
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
    final Pal pal = Pal.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StaggerIn(
              index: 0,
              dy: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.rMd),
                child: SizedBox(
                  height: 116,
                  width: double.infinity,
                  child: productImage(sheetContext, product.imageUrl),
                ),
              ),
            ),
            const SizedBox(height: 11),
            StaggerIn(
              index: 1,
              dy: 8,
              child: Text(product.name,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: pal.ink)),
            ),
            const SizedBox(height: 3),
            StaggerIn(
              index: 2,
              dy: 8,
              child: Text(
                  '${product.category} · ${product.stockLabel} · ${product.barcode}',
                  style: TextStyle(
                      fontSize: 11.5, color: pal.muted)),
            ),
            const SizedBox(height: 4),
            StaggerIn(
              index: 3,
              dy: 8,
              child: Text(money(product.price),
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: pal.accent)),
            ),
            const SizedBox(height: 12),
            StaggerIn(
              index: 4,
              dy: 8,
              child: PressableScale(
                child: FilledButton(
                  style: AppTheme.primaryButton(sheetContext),
                  onPressed: product.isOutOfStock
                      ? null
                      : () {
                          sheetContext.read<Store>().addToCart(
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
              ),
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
        title: const Text('No match'),
        content:
            Text('No product found for "$code". Add it to the catalog now?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Not now',
                style: TextStyle(color: Pal.of(dialogContext).muted)),
          ),
          FilledButton(
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
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.rLg),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    if (widget.active)
                      _ScannerArea(onDetect: _onDetect)
                    else
                      const ColoredBox(
                        color: AppTheme.scannerBg,
                        child: Center(
                          child: Text('Camera idle',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12.5)),
                        ),
                      ),
                    Center(
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 1.6),
                        ),
                      ),
                    ),
                    // Sweeping scan line — only runs while the tab is live.
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _ScanLine(active: widget.active),
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
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(
                    controller: _manual,
                    onSubmitted: _handleCode,
                    textInputAction: TextInputAction.go,
                    style: TextStyle(
                        fontSize: 13, color: Pal.of(context).ink),
                    decoration: AppTheme.input(
                        context, 'Enter barcode or name',
                        icon: Icons.dialpad),
                  ),
                  const SizedBox(height: 8),
                  PressableScale(
                    child: OutlinedButton(
                      onPressed: () => _handleCode(_manual.text),
                      child: const Text('Find product'),
                    ),
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

/// A soft accent line that sweeps up and down inside the scan viewport.
/// The repeat animation only runs while [active] is true, so idle tabs
/// (and widget tests over an IndexedStack) never tick a frame.
class _ScanLine extends StatefulWidget {
  const _ScanLine({required this.active});

  final bool active;

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_ScanLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final bool on = widget.active && _controller.isAnimating;
        return Align(
          alignment: Alignment(0, on ? _controller.value * 2 - 1 : -1.2),
          child: Opacity(
            opacity: on ? 0.9 : 0,
            child: child,
          ),
        );
      },
      child: Container(
        width: 150,
        height: 2.4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: <Color>[
              Color(0x00D97A4E),
              Color(0xFFD97A4E),
              Color(0x00D97A4E),
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFFD97A4E).withValues(alpha: 0.35),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
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
        color: AppTheme.scannerBg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.videocam_off_outlined,
                  color: Colors.white54, size: 28),
              SizedBox(height: 8),
              Text('Camera not available here',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              SizedBox(height: 3),
              Text('Use manual entry below to find products.',
                  style: TextStyle(color: Colors.white38, fontSize: 10.5)),
            ],
          ),
        ),
      );
    }
    final MobileScannerController? controller = _controller;
    if (controller == null) {
      return const ColoredBox(
        color: AppTheme.scannerBg,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 1.8, color: Colors.white70),
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
