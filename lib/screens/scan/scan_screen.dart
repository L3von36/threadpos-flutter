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
import '../sell/product_detail_sheet.dart';

/// Barcode scanning tab. Uses the camera via mobile_scanner when
/// available and always offers a manual barcode entry fallback, plus a
/// shift-scoped recent-lookups strip like the reference design.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.active = false});

  /// True while this tab is selected; the camera only runs when active.
  final bool active;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final TextEditingController _manual = TextEditingController();
  final FocusNode _manualFocus = FocusNode();
  bool _lock = false;
  String? _noMatchCode;

  @override
  void dispose() {
    _manual.dispose();
    _manualFocus.dispose();
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
      setState(() => _noMatchCode = null);
      store.pushLookup(product);
      _showFound(product);
    } else {
      // Inline "no match" error state (no dialog), like the reference.
      setState(() => _noMatchCode = code.trim());
      _lock = false;
    }
  }

  Future<void> _showFound(Product product) async {
    final Pal pal = Pal.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Step header, like the reference scan flow.
            StaggerIn(
              index: 0,
              dy: 6,
              child: Row(
                children: <Widget>[
                  Text('STEP 2 · MATCH FOUND',
                      style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                          color: pal.accent)),
                  const Spacer(),
                  PressableScale(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    pressedScale: 0.85,
                    child: Icon(Icons.close,
                        size: 18, color: pal.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            StaggerIn(
              index: 0,
              dy: 6,
              child: Text('Review product details',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: pal.ink)),
            ),
            const SizedBox(height: 11),
            StaggerIn(
              index: 1,
              dy: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.rMd),
                child: SizedBox(
                  height: 104,
                  width: double.infinity,
                  child: productImage(sheetContext, product.imageUrl),
                ),
              ),
            ),
            const SizedBox(height: 11),
            StaggerIn(
              index: 2,
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
                  '${product.category} · SKU ${product.id.toUpperCase()}',
                  style: TextStyle(
                      fontSize: 11.5, color: pal.muted)),
            ),
            const SizedBox(height: 5),
            StaggerIn(
              index: 3,
              dy: 8,
              child: Row(
                children: <Widget>[
                  Text(money(product.price),
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: pal.accent)),
                  const Spacer(),
                  Text(product.floorLabel,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: product.isOutOfStock
                              ? pal.danger
                              : (product.isLowStock
                                  ? pal.amber
                                  : pal.sage))),
                ],
              ),
            ),
            const SizedBox(height: 11),
            StaggerIn(
              index: 4,
              dy: 8,
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: pal.surfaceAlt.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                ),
                child: Column(
                  children: <Widget>[
                    _SpecRow(
                        label: 'BARCODE', value: product.barcode),
                    const SizedBox(height: 7),
                    _SpecRow(
                        label: 'SIZES ON HAND',
                        value: product.sizes.isEmpty
                            ? 'One size'
                            : product.sizes.join(' · ')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 13),
            StaggerIn(
              index: 5,
              dy: 8,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: PressableScale(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          showProductDetailSheet(context, product);
                        },
                        child: const Text('View full details',
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
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
                                showAddedToast(
                                    sheetContext, product.name);
                              },
                        child: const Text('Start sale'),
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
    if (mounted) setState(() => _lock = false);
  }

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);

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
          // Recent lookups this shift — slides in when the first
          // successful lookup happens.
          AnimatedSize(
            duration: Motion.base,
            curve: Motion.out,
            alignment: Alignment.topCenter,
            child: store.recentLookups.isEmpty
                ? const SizedBox(width: double.infinity)
                : SizedBox(
                    height: 74,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(14, 7, 14, 5),
                          child: Text('RECENT LOOKUPS · SCANNED THIS SHIFT',
                              style: TextStyle(
                                  fontSize: 9.5,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w700,
                                  color: pal.muted)),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            scrollDirection: Axis.horizontal,
                            itemCount: store.recentLookups.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 7),
                            itemBuilder: (BuildContext context, int i) {
                              final Product p = store.recentLookups[i];
                              return StaggerIn(
                                index: i,
                                dy: 6,
                                child: PressableScale(
                                  onTap: () {
                                    _lock = true;
                                    _showFound(p);
                                  },
                                  pressedScale: 0.94,
                                  child: Container(
                                    width: 168,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: pal.surface,
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.rSm),
                                      border: Border.all(
                                          color: pal.border),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(7),
                                          child: SizedBox(
                                            width: 34,
                                            height: 34,
                                            child: productImage(
                                                context, p.imageUrl),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Text(p.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow
                                                          .ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 11.5,
                                                      height: 1.1,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: pal.ink)),
                                              const SizedBox(height: 2),
                                              Text(
                                                  '${p.barcode} · ${p.stock} left',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow
                                                          .ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 9.5,
                                                      color:
                                                          pal.muted)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
                    focusNode: _manualFocus,
                    onSubmitted: _handleCode,
                    textInputAction: TextInputAction.go,
                    style: TextStyle(
                        fontSize: 13, color: pal.ink),
                    decoration: AppTheme.input(
                        context, 'Enter 12-digit barcode or name',
                        icon: Icons.dialpad),
                  ),
                  const SizedBox(height: 8),
                  PressableScale(
                    child: OutlinedButton(
                      onPressed: () => _handleCode(_manual.text),
                      child: const Text('Look up'),
                    ),
                  ),
                  // Inline no-match error card with retry + add actions.
                  AnimatedSize(
                    duration: Motion.base,
                    curve: Motion.out,
                    alignment: Alignment.topCenter,
                    child: _noMatchCode == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: StaggerIn(
                              index: 0,
                              dy: 8,
                              child: Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: pal.danger
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.rMd),
                                  border: Border.all(
                                      color: pal.danger
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        PopIn(
                                          begin: 0.5,
                                          duration: Motion.base,
                                          child: Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: pal.danger
                                                  .withValues(
                                                      alpha: 0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                                Icons.search_off_rounded,
                                                size: 15,
                                                color: pal.danger),
                                          ),
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                              'No match for that barcode',
                                              style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: pal.ink)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Check the label or ask a manager to add '
                                      '"$_noMatchCode" to the catalog.',
                                      style: TextStyle(
                                          fontSize: 11,
                                          height: 1.35,
                                          color: pal.muted),
                                    ),
                                    const SizedBox(height: 9),
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: PressableScale(
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                minimumSize:
                                                    const Size.fromHeight(36),
                                                side: BorderSide(
                                                    color: pal.danger),
                                                foregroundColor:
                                                    pal.danger,
                                              ),
                                              onPressed: () {
                                                setState(() =>
                                                    _noMatchCode = null);
                                                _manualFocus
                                                    .requestFocus();
                                              },
                                              child: const Text(
                                                  'Try another barcode',
                                                  overflow:
                                                      TextOverflow
                                                          .ellipsis),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: PressableScale(
                                            child: FilledButton(
                                              style: FilledButton.styleFrom(
                                                minimumSize:
                                                    const Size.fromHeight(36),
                                                backgroundColor:
                                                    pal.ink,
                                                foregroundColor:
                                                    pal.toastText,
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        AddProductScreen(
                                                            initialBarcode:
                                                                _noMatchCode),
                                                  ),
                                                );
                                                setState(() =>
                                                    _noMatchCode = null);
                                              },
                                              child: const Text(
                                                  'Add product',
                                                  overflow:
                                                      TextOverflow
                                                          .ellipsis),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 92,
          child: Text(label,
              style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w700,
                  color: pal.muted)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: pal.ink)),
        ),
      ],
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
