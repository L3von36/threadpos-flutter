import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/seed_data.dart';
import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

/// Manager approval hub: two tabs —
///  * Products: clothing pieces submitted by sellers, awaiting publish.
///  * Requests: discounts, price changes, restocks, time-off.
class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final int productCount = store.pendingProductCount;
    final int requestCount = store.approvals.length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Approvals'),
          bottom: TabBar(
            labelColor: pal.accent,
            unselectedLabelColor: pal.muted,
            indicatorColor: pal.accent,
            labelStyle: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700),
            tabs: <Widget>[
              Tab(
                  child: Text(productCount > 0
                      ? 'Products · $productCount'
                      : 'Products')),
              Tab(
                  child: Text(requestCount > 0
                      ? 'Requests · $requestCount'
                      : 'Requests')),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _ProductApprovalsTab(),
            _RequestsTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — new clothing awaiting manager approval
// ---------------------------------------------------------------------------

class _ProductApprovalsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final List<Product> pending = store.pendingProducts;

    if (pending.isEmpty) {
      return const EmptyState(
        icon: Icons.checkroom_outlined,
        title: 'No pieces waiting',
        subtitle:
            'Seller submissions will land here before joining the catalog.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int i) {
        final Product p = pending[i];
        return StaggerIn(
          index: i,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: pal.surface,
              borderRadius: BorderRadius.circular(AppTheme.rLg),
              border: Border.all(color: pal.amber.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppTheme.rMd),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: productImage(context, p.imageUrl),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: pal.ink)),
                          Text(
                              '${p.category} · ${money(p.price)} · ${p.stock} pcs',
                              style: TextStyle(
                                  fontSize: 11, color: pal.muted)),
                          Text(
                              'Submitted by ${_submitterLabel(p.addedBy)} · ${clockLabel(p.addedAt)}',
                              style: TextStyle(
                                  fontSize: 10.5, color: pal.muted)),
                        ],
                      ),
                    ),
                    StockBadge(label: 'Pending', color: pal.amber),
                  ],
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: pal.surfaceAlt.withValues(alpha: 0.6),
                    borderRadius:
                        BorderRadius.circular(AppTheme.rSm),
                  ),
                  child: BarcodeView(value: p.barcode, height: 26),
                ),
                const SizedBox(height: 9),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: PressableScale(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(34),
                            side: BorderSide(
                                color:
                                    pal.danger.withValues(alpha: 0.6)),
                            foregroundColor: pal.danger,
                          ),
                          onPressed: () => _reject(context, p),
                          child: const Text('Decline'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PressableScale(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(34),
                            backgroundColor: pal.sage,
                          ),
                          onPressed: () => _approve(context, p),
                          child: const Text('Approve'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _submitterLabel(String email) {
    if (email.isEmpty) return 'a seller';
    return email.split('@').first;
  }

  void _approve(BuildContext context, Product p) {
    context.read<Store>().approveProduct(p.id);
    showSnack(context, '${p.name} published to the catalog');
  }

  void _reject(BuildContext context, Product p) {
    final Pal pal = Pal.of(context);
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.rLg)),
        title: Text('Decline ${p.name}?',
            style: const TextStyle(fontSize: 16)),
        content: Text(
            'The submission will be removed from the queue and the seller notified.',
            style: TextStyle(fontSize: 12.5, color: pal.muted)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: pal.danger,
                foregroundColor: Colors.white),
            onPressed: () {
              context.read<Store>().rejectProduct(p.id);
              Navigator.of(dialogContext).pop();
              showSnack(context, '${p.name} declined');
            },
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — discount / price / restock / time-off requests
// ---------------------------------------------------------------------------

class _RequestsTab extends StatefulWidget {
  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  final List<OpsItem> _pending = List<OpsItem>.from(seedApprovals);

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    if (_pending.isEmpty) {
      return const EmptyState(
        icon: Icons.task_alt,
        title: 'All clear',
        subtitle: 'No requests are waiting on a decision.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int i) {
        final OpsItem item = _pending[i];
        return StaggerIn(
          index: i,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: pal.surface,
              borderRadius: BorderRadius.circular(AppTheme.rMd),
              border: Border.all(color: pal.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: pal.accent.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child:
                          Icon(item.icon, size: 16, color: pal.accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(item.title,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: pal.ink)),
                          Text(item.subtitle,
                              style: TextStyle(
                                  fontSize: 11, color: pal.muted)),
                        ],
                      ),
                    ),
                    Text(item.meta,
                        style:
                            TextStyle(fontSize: 10, color: pal.muted)),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: PressableScale(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(34),
                            side: BorderSide(
                                color:
                                    pal.danger.withValues(alpha: 0.6)),
                            foregroundColor: pal.danger,
                          ),
                          onPressed: () =>
                              _decide(context, i, approved: false),
                          child: const Text('Decline'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PressableScale(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(34),
                            backgroundColor: pal.sage,
                          ),
                          onPressed: () =>
                              _decide(context, i, approved: true),
                          child: const Text('Approve'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _decide(BuildContext context, int index, {required bool approved}) {
    final OpsItem item = _pending[index];
    setState(() => _pending.removeAt(index));
    showSnack(context,
        '${item.title} ${approved ? 'approved' : 'declined'}');
  }
}
