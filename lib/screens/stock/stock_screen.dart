import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import '../manager/approval_screens.dart';

/// Stock room: on-hand KPI header, filter chips, restock requests and —
/// for managers — multi-location tabs, network sync status, transfers
/// and the transfer queue, matching the reference network-stock view.
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _filter = 'All';
  int _location = -1; // -1 = all locations
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final bool manager = store.isManager;

    final List<Product> items = store.products.where((Product p) {
      if (_searchQuery.isNotEmpty) {
        final bool matchName = p.name.toLowerCase().contains(_searchQuery);
        final bool matchSku = p.barcode.toLowerCase().contains(_searchQuery);
        if (!matchName && !matchSku) return false;
      }
      switch (_filter) {
        case 'Low':
          return p.isLowStock || p.isOutOfStock;
        case 'Out':
          return p.isOutOfStock;
        case 'Requests':
          return store.isRestockRequested(p.id);
        default:
          return true;
      }
    }).toList();

    final int onHand = _location < 0
        ? store.totalUnits
        : store.products.fold(
            0, (int s, Product p) => s + store.unitsAt(p, _location));

    return Scaffold(
      appBar: AppBar(
        title: Text(manager ? 'Inventory control' : 'Stock'),
        actions: <Widget>[
          if (manager)
            IconButton(
              tooltip: 'Sync now',
              icon: const Icon(Icons.sync, size: 19),
              onPressed: () {
                store.syncNow();
                showSnack(context, 'All stores synced');
              },
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
        children: <Widget>[
          // Network sync status (manager only).
          if (manager) ...<Widget>[
            StaggerIn(
              index: 0,
              dy: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: pal.sage.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                  border: Border.all(
                      color: pal.sage.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.cloud_done_outlined,
                        size: 16, color: pal.sage),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All stores synced · ${store.syncedLabel} · ${Store.locations.length} locations',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: pal.ink),
                      ),
                    ),
                    PressableScale(
                      onTap: () {
                        store.syncNow();
                        showSnack(context, 'All stores synced');
                      },
                      pressedScale: 0.92,
                      child: Text('Sync now',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: pal.accent)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // New-clothing approval queue (manager only).
            if (store.pendingProductCount > 0) ...<Widget>[
              StaggerIn(
                index: 1,
                dy: 8,
                child: PressableScale(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const ApprovalsScreen()),
                  ),
                  pressedScale: 0.97,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: pal.amber.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.rMd),
                      border: Border.all(
                          color:
                              pal.amber.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.checkroom,
                            size: 16, color: pal.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${store.pendingProductCount} new piece${store.pendingProductCount == 1 ? '' : 's'} awaiting approval',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: pal.ink),
                          ),
                        ),
                        Text('Review',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: pal.accent)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          // On-hand summary card with mini KPIs.
          StaggerIn(
            index: 1,
            dy: 8,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pal.surface,
                borderRadius: BorderRadius.circular(AppTheme.rLg),
                border: Border.all(color: pal.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('ON HAND TODAY',
                      style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                          color: pal.muted)),
                  const SizedBox(height: 3),
                  Text(
                    '$onHand units across ${store.products.length} active styles',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: pal.ink),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MiniKpi(
                          label: 'Low stock',
                          value: '${store.lowStockProducts.length}',
                          color: pal.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniKpi(
                          label: 'Incoming',
                          value: '${store.incomingUnits}',
                          color: pal.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniKpi(
                          label: 'Accuracy',
                          value: '91%',
                          color: pal.sage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Location tabs (manager network view).
          if (manager) ...<Widget>[
            const SizedBox(height: 10),
            SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 1),
                children: <Widget>[
                  _LocationChip(
                    label: 'All locations',
                    selected: _location == -1,
                    onTap: () => setState(() => _location = -1),
                  ),
                  for (int i = 0; i < Store.locations.length; i++)
                    _LocationChip(
                      label: Store.locations[i],
                      selected: _location == i,
                      onTap: () => setState(() => _location = i),
                    ),
                ].map((Widget w) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: w,
                    )).toList(),
              ),
            ),
          ],
          // Needs-attention banner.
          if (store.lowStockProducts.isNotEmpty &&
              _filter != 'Low' &&
              _filter != 'Requests') ...<Widget>[
            const SizedBox(height: 10),
            StaggerIn(
              index: 2,
              dy: 8,
              child: PressableScale(
                onTap: () => setState(() => _filter = 'Low'),
                pressedScale: 0.97,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: pal.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.rMd),
                    border: Border.all(
                        color: pal.amber.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: pal.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            '${store.lowStockProducts.length} styles need attention',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: pal.ink)),
                      ),
                      Text('Review',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: pal.amber)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Search bar.
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: pal.surface,
              borderRadius: BorderRadius.circular(AppTheme.rMd),
              border: Border.all(color: pal.border),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 13, color: pal.ink),
              decoration: InputDecoration(
                hintText: 'Search products by name or SKU...',
                hintStyle: TextStyle(fontSize: 13, color: pal.muted),
                prefixIcon: Icon(Icons.search, size: 18, color: pal.muted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 16, color: pal.muted),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips.
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 1),
              children: <String>['All', 'Low', 'Out', 'Requests']
                  .map((String f) => Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ChoiceChip(
                          label: Text(f == 'All'
                              ? 'All products'
                              : (f == 'Low' ? 'Needs attention' : f)),
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
          const SizedBox(height: 8),
          if (_filter == 'Low')
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('Needs attention',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: pal.ink)),
              ),
            ),
          // Product rows.
          if (items.isEmpty)
            const EmptyState(
              icon: Icons.inventory_outlined,
              title: 'Nothing here',
              subtitle: 'No products match this filter right now.',
            )
          else
            ...items.asMap().entries.map((MapEntry<int, Product> entry) {
              final Product p = entry.value;
              return StaggerIn(
                index: entry.key,
                child: _StockRow(
                  product: p,
                  locationLabel: _location < 0
                      ? null
                      : Store.locations[_location],
                  units: _location < 0
                      ? p.stock
                      : store.unitsAt(p, _location),
                ),
              );
            }),
          // Transfer queue (manager only).
          if (manager && store.transfers.isNotEmpty) ...<Widget>[
            const SectionHeader(title: 'Network movement'),
            ...store.transfers.asMap().entries.map(
                  (MapEntry<int, TransferOrder> entry) => StaggerIn(
                    index: entry.key,
                    dy: 8,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: pal.surface,
                        borderRadius:
                            BorderRadius.circular(AppTheme.rMd),
                        border: Border.all(color: pal.border),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.local_shipping_outlined,
                              size: 16,
                              color: entry.value.inTransit
                                  ? pal.accent
                                  : pal.sage),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                    '${entry.value.id} · ${entry.value.qty} × ${entry.value.productName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: pal.ink)),
                                Text(
                                    '${entry.value.from} → ${entry.value.to}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: pal.muted)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StockBadge(
                            label: entry.value.inTransit
                                ? 'In transit'
                                : 'Delivered',
                            color: entry.value.inTransit
                                ? pal.sage
                                : pal.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.rSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10, color: pal.muted)),
        ],
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.out,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? pal.accent : pal.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? pal.accent : pal.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : pal.ink)),
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({
    required this.product,
    required this.units,
    this.locationLabel,
  });

  final Product product;
  final int units;
  final String? locationLabel;

  bool get _low => locationLabel == null
      ? product.isLowStock || product.isOutOfStock
      : units <= 3;

  Future<void> _showRestockDialog(BuildContext context) async {
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
                style:
                    TextStyle(color: Pal.of(dialogContext).muted)),
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

  Future<void> _showTransferDialog(BuildContext context) async {
    final TextEditingController qty = TextEditingController(text: '1');
    String destination = Store.locations.last;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter setDialog) {
          final Pal pal = Pal.of(dialogContext);
          return AlertDialog(
            title: Text('Transfer ${product.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: qty,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 13, color: pal.ink),
                  decoration:
                      AppTheme.input(dialogContext, 'Units to move'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: destination,
                  decoration: AppTheme.input(dialogContext, 'To location'),
                  items: Store.locations
                      .map((String l) => DropdownMenuItem<String>(
                            value: l,
                            child: Text(l,
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (String? v) =>
                      setDialog(() => destination = v ?? destination),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancel', style: TextStyle(color: pal.muted)),
              ),
              PressableScale(
                child: FilledButton(
                  onPressed: () {
                    final int amount = int.tryParse(qty.text.trim()) ?? 0;
                    if (amount > 0) {
                      context
                          .read<Store>()
                          .createTransfer(product, amount, destination);
                    }
                    Navigator.of(dialogContext).pop();
                    showSnack(
                        context, 'Transfer queued · $amount × ${product.name}');
                  },
                  child: const Text('Transfer'),
                ),
              ),
            ],
          );
        },
      ),
    );
    qty.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final bool manager = store.isManager;
    final bool requested = store.isRestockRequested(product.id);
    final Color badgeColor = _low
        ? (units <= 0 ? pal.danger : pal.amber)
        : pal.sage;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        border: Border.all(color: pal.border),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              width: 46,
              height: 46,
              child: productImage(context, product.imageUrl),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: pal.ink)),
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: StockBadge(
                        label: locationLabel == null
                            ? product.stockLabel
                            : '$units units at location',
                        color: badgeColor,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                          locationLabel == null
                              ? product.category
                              : '${product.category} · $locationLabel',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10.5, color: pal.muted)),
                    ),
                  ],
                ),
                if (_low && requested) ...<Widget>[
                  const SizedBox(height: 5),
                  Row(
                    children: <Widget>[
                      PopIn(
                        begin: 0.5,
                        duration: Motion.base,
                        child: Icon(Icons.check_circle_rounded,
                            size: 13, color: pal.sage),
                      ),
                      const SizedBox(width: 5),
                      Text('Request sent',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: pal.sage)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Restock request / sent state for low rows.
          if (_low && !requested)
            PressableScale(
              onTap: () {
                store.requestRestock(product.id);
                showSnack(context,
                    'Restock request sent for ${product.name}');
              },
              pressedScale: 0.94,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: pal.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Request restock',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: pal.amber)),
              ),
            ),
          if (manager) ...<Widget>[
            const SizedBox(width: 2),
            PressableScale(
              pressedScale: 0.82,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Transfer',
                icon: Icon(Icons.swap_horiz_rounded,
                    size: 18, color: pal.accent),
                onPressed: () => _showTransferDialog(context),
              ),
            ),
          ],
          PressableScale(
            pressedScale: 0.82,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Restock',
              icon: Icon(Icons.add_box_outlined,
                  size: 19, color: pal.accent),
              onPressed: () => _showRestockDialog(context),
            ),
          ),
        ],
      ),
    );
  }
}
