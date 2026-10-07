import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'payment_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: store.cart.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Cart is empty',
              subtitle:
                  'Browse the catalog on the Sell tab and add items.',
            )
          : Column(
              children: <Widget>[
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    itemCount: store.cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int i) {
                      final CartItem item = store.cart[i];
                      return StaggerIn(
                        index: i,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: pal.surface,
                            borderRadius:
                                BorderRadius.circular(AppTheme.rMd),
                            border: Border.all(color: pal.border),
                          ),
                          child: Row(
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: SizedBox(
                                  width: 46,
                                  height: 46,
                                  child: productImage(
                                      context, item.product.imageUrl),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(item.product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: pal.ink)),
                                    const SizedBox(height: 2),
                                    Text(
                                        item.size.isEmpty
                                            ? money(item.product.price)
                                            : 'Size ${item.size} · ${money(item.product.price)}',
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            color: pal.muted)),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: pal.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    PressableScale(
                                      onTap: () =>
                                          store.changeQty(item, -1),
                                      pressedScale: 0.75,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.all(5),
                                        child: Icon(Icons.remove,
                                            size: 14, color: pal.ink),
                                      ),
                                    ),
                                    BumpOnChange(
                                      trigger: item.qty,
                                      amount: 0.3,
                                      child: Text('${item.qty}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              color: pal.ink)),
                                    ),
                                    PressableScale(
                                      onTap: () =>
                                          store.changeQty(item, 1),
                                      pressedScale: 0.75,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.all(5),
                                        child: Icon(Icons.add,
                                            size: 14, color: pal.ink),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 70,
                                child: Text(money(item.lineTotal),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: pal.accent)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: BoxDecoration(
                    color: pal.surface,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                          color: pal.dark
                              ? Colors.black.withValues(alpha: 0.4)
                              : const Color(0x14000000),
                          blurRadius: 10,
                          offset: const Offset(0, -3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                              '${store.cartCount} item${store.cartCount == 1 ? '' : 's'}',
                              style: TextStyle(
                                  fontSize: 11.5, color: pal.muted)),
                          PressableScale(
                            onTap: store.clearCart,
                            pressedScale: 0.92,
                            child: Text('Clear',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: pal.danger)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('Subtotal',
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: pal.ink)),
                          CountUpText(
                            store.cartTotal,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: pal.accent),
                            formatter: money,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      PressableScale(
                        child: FilledButton(
                          style: AppTheme.primaryButton(context),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const PaymentScreen()),
                          ),
                          child: const Text('Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
