import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../add/add_product_screen.dart';

/// Modal bottom sheet for fast camera barcode scanning in the Seller POS interface.
Future<void> showPosBarcodeScanner(
  BuildContext context, {
  required ValueChanged<Product> onProductFound,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) => _PosCameraScannerSheet(
      onProductFound: onProductFound,
    ),
  );
}

class _PosCameraScannerSheet extends StatefulWidget {
  const _PosCameraScannerSheet({required this.onProductFound});

  final ValueChanged<Product> onProductFound;

  @override
  State<_PosCameraScannerSheet> createState() => _PosCameraScannerSheetState();
}

class _PosCameraScannerSheetState extends State<_PosCameraScannerSheet>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _cameraFailed = false;
  bool _isLocked = false;
  bool _isTorchOn = false;
  String? _unrecognizedBarcode;
  final TextEditingController _manualInput = TextEditingController();

  late final AnimationController _laserAnim;

  @override
  void initState() {
    super.initState();
    _laserAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _initScanner();
  }

  Future<void> _initScanner() async {
    final MobileScannerController controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.normal,
    );
    try {
      await controller.start();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _cameraFailed = true);
    }
  }

  @override
  void dispose() {
    _laserAnim.dispose();
    _controller?.dispose();
    _manualInput.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isLocked || !mounted) return;
    for (final Barcode barcode in capture.barcodes) {
      final String? code = barcode.rawValue;
      if (code == null || code.trim().isEmpty) continue;
      _isLocked = true;
      _handleDetectedCode(code.trim());
      return;
    }
  }

  void _handleDetectedCode(String code) {
    final Store store = context.read<Store>();
    final Product? product =
        store.findByBarcode(code) ?? store.findByName(code);

    if (!mounted) return;

    if (product != null) {
      setState(() => _unrecognizedBarcode = null);
      store.pushLookup(product);

      // Close scanner sheet and notify caller with the found product
      Navigator.of(context).pop();
      widget.onProductFound(product);
    } else {
      setState(() {
        _unrecognizedBarcode = code;
        _isLocked = false;
      });
    }
  }

  void _toggleTorch() {
    final MobileScannerController? ctrl = _controller;
    if (ctrl == null) return;
    try {
      ctrl.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {}
  }

  void _switchCamera() {
    final MobileScannerController? ctrl = _controller;
    if (ctrl == null) return;
    try {
      ctrl.switchCamera();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    final Store store = context.watch<Store>();
    final double sheetHeight = MediaQuery.of(context).size.height * 0.78;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: pal.border, width: 1),
      ),
      child: Column(
        children: <Widget>[
          // Header Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: pal.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Top action bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: pal.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.qr_code_scanner_rounded,
                      size: 20, color: pal.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('POS BARCODE SCANNER',
                          style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                              color: pal.accent)),
                      const SizedBox(height: 2),
                      Text('Camera product lookup',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: pal.ink)),
                    ],
                  ),
                ),
                if (!_cameraFailed && _controller != null) ...<Widget>[
                  IconButton(
                    tooltip: _isTorchOn ? 'Turn Flash Off' : 'Turn Flash On',
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on : Icons.flash_off,
                      size: 20,
                      color: _isTorchOn ? pal.amber : pal.muted,
                    ),
                    onPressed: _toggleTorch,
                  ),
                  IconButton(
                    tooltip: 'Flip Camera',
                    icon: const Icon(Icons.flip_camera_ios_outlined, size: 20),
                    onPressed: _switchCamera,
                  ),
                ],
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Main View: Camera or Fallback
          Expanded(
            child: _cameraFailed
                ? _buildEmulatorFallback(pal, store)
                : _buildCameraScanner(pal),
          ),

          // Unrecognized Barcode Alert (if any)
          if (_unrecognizedBarcode != null)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: pal.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pal.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.error_outline, size: 18, color: pal.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Barcode not found: $_unrecognizedBarcode',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: pal.danger),
                        ),
                        Text(
                          'Item is not currently cataloged in the inventory system.',
                          style: TextStyle(fontSize: 10.5, color: pal.muted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final String code = _unrecognizedBarcode!;
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AddProductScreen(initialBarcode: code),
                        ),
                      );
                    },
                    child: Text('Add Item',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: pal.accent)),
                  ),
                ],
              ),
            ),

          // Bottom Quick Barcode Manual Lookup Strip
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: pal.surfaceAlt.withValues(alpha: 0.5),
              border: Border(top: BorderSide(color: pal.border, width: 0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Quick Manual Search or Scan Simulation',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: pal.muted),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _manualInput,
                          style: TextStyle(fontSize: 12.5, color: pal.ink),
                          decoration: InputDecoration(
                            hintText: 'Enter barcode or SKU (e.g. 629100010001)',
                            hintStyle: TextStyle(
                                fontSize: 11.5, color: pal.muted.withValues(alpha: 0.7)),
                            prefixIcon: const Icon(Icons.keyboard_outlined, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            filled: true,
                            fillColor: pal.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: pal.border),
                            ),
                          ),
                          onSubmitted: (String val) {
                            if (val.trim().isNotEmpty) {
                              _handleDetectedCode(val.trim());
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pal.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        if (_manualInput.text.trim().isNotEmpty) {
                          _handleDetectedCode(_manualInput.text.trim());
                        }
                      },
                      child: const Text('Lookup', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraScanner(Pal pal) {
    final MobileScannerController? ctrl = _controller;
    if (ctrl == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 2.2, color: pal.accent),
            ),
            const SizedBox(height: 12),
            Text('Starting camera scanner...',
                style: TextStyle(fontSize: 12, color: pal.muted)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            MobileScanner(
              controller: ctrl,
              onDetect: _onDetect,
            ),

            // Translucent dark vignette around scanner area
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 1.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  children: <Widget>[
                    // Corner targeting brackets
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _bracketCorner(pal, top: true, left: true),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _bracketCorner(pal, top: true, left: false),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: _bracketCorner(pal, top: false, left: true),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _bracketCorner(pal, top: false, left: false),
                    ),

                    // Animated laser scan beam
                    AnimatedBuilder(
                      animation: _laserAnim,
                      builder: (BuildContext context, _) {
                        return Positioned(
                          top: 10 + (_laserAnim.value * 220),
                          left: 12,
                          right: 12,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: pal.accent,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: pal.accent.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Top caption overlay
            Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.crop_free, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Align barcode inside frame',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bracketCorner(Pal pal, {required bool top, required bool left}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? BorderSide(color: pal.accent, width: 3.5)
              : BorderSide.none,
          bottom: !top
              ? BorderSide(color: pal.accent, width: 3.5)
              : BorderSide.none,
          left: left
              ? BorderSide(color: pal.accent, width: 3.5)
              : BorderSide.none,
          right: !left
              ? BorderSide(color: pal.accent, width: 3.5)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildEmulatorFallback(Pal pal, Store store) {
    final List<Product> sampleProducts = store.products.take(6).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: pal.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: pal.border),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: pal.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_outlined,
                      size: 20, color: pal.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Camera Preview Unavailable',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: pal.ink)),
                      const SizedBox(height: 2),
                      Text(
                        'Running on emulator or browser sandbox without webcam access. Use barcode chips below to test fast scanning.',
                        style: TextStyle(fontSize: 11, color: pal.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'TAP SAMPLE BARCODES TO SIMULATE INSTANT SCAN:',
            style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: pal.accent),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: sampleProducts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (BuildContext context, int index) {
                final Product p = sampleProducts[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _handleDetectedCode(p.barcode),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: pal.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: pal.border),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.qr_code_2_rounded,
                            size: 22, color: pal.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(p.name,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: pal.ink)),
                              Text('Barcode: ${p.barcode} · ${p.category}',
                                  style: TextStyle(
                                      fontSize: 11, color: pal.muted)),
                            ],
                          ),
                        ),
                        Text(
                          money(p.price),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: pal.ink),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_ios,
                            size: 12, color: pal.muted),
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
}
