import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'success_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.cash;
  final TextEditingController _received = TextEditingController();

  @override
  void dispose() {
    _received.dispose();
    super.dispose();
  }

  double? get _receivedAmount {
    if (_method != PaymentMethod.cash) return null;
    return double.tryParse(_received.text.trim().replaceAll(',', ''));
  }

  bool get _canComplete {
    if (_method != PaymentMethod.cash) return true;
    final double? amount = _receivedAmount;
    if (amount == null) return false;
    final Store store = context.read<Store>();
    return amount + 0.01 >= store.cartTotal;
  }

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    final double total = store.cartTotal;

    return Scaffold(
      appBar: AppBar(title: const Text('Take payment')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: pal.accent,
              borderRadius: BorderRadius.circular(AppTheme.rLg),
            ),
            child: Column(
              children: <Widget>[
                Text('Amount due',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                CountUpText(
                  total,
                  style: TextStyle(
                      fontSize: 25,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                  formatter: money,
                ),
                const SizedBox(height: 3),
                Text('${store.cartCount} item(s) in cart',
                    style: TextStyle(
                        fontSize: 11.5, color: Colors.white70)),
              ],
            ),
          ),
          const SectionHeader(title: 'Payment method'),
          Row(
            children: <Widget>[
              for (final PaymentMethod m in PaymentMethod.values)
                Expanded(
                  child: PressableScale(
                    onTap: () => setState(() => _method = m),
                    pressedScale: 0.94,
                    child: AnimatedContainer(
                      duration: Motion.base,
                      curve: Motion.out,
                      margin: EdgeInsets.only(
                          right: m == PaymentMethod.mobile ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _method == m
                            ? pal.softAccent
                            : pal.surface,
                        borderRadius:
                            BorderRadius.circular(AppTheme.rMd),
                        border: Border.all(
                          color: _method == m ? pal.accent : pal.border,
                          width: _method == m ? 1.4 : 1,
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          AnimatedScale(
                            duration: Motion.base,
                            curve: Motion.pop,
                            scale: _method == m ? 1.12 : 1.0,
                            child: Icon(paymentMethodIcon(m),
                                size: 19,
                                color: _method == m
                                    ? pal.accent
                                    : pal.muted),
                          ),
                          const SizedBox(height: 5),
                          Text(paymentMethodLabel(m),
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _method == m
                                      ? pal.accent
                                      : pal.ink)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_method == PaymentMethod.cash) ...<Widget>[
            const SectionHeader(title: 'Cash received'),
            TextField(
              controller: _received,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 13, color: pal.ink),
              decoration: AppTheme.input(context, 'Amount received',
                  icon: Icons.payments_outlined, hint: money(total)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: <Widget>[
                _quickChip(context, 'Exact', total),
                _quickChip(context, '+500', total + 500),
                _quickChip(context, '+1000', total + 1000),
                _quickChip(context, '+2000', total + 2000),
              ],
            ),
            if (_receivedAmount != null) ...<Widget>[
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: Motion.base,
                switchInCurve: Motion.out,
                switchOutCurve: Curves.easeIn,
                transitionBuilder:
                    (Widget child, Animation<double> anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.25),
                              end: Offset.zero)
                          .animate(anim),
                      child: child,
                    ),
                  );
                },
                child: Builder(
                  key: ValueKey<String>(
                      ((_receivedAmount ?? 0) - total).toStringAsFixed(2)),
                  builder: (BuildContext context) {
                    final double change =
                        (_receivedAmount ?? 0) - total;
                    final bool enough = change >= 0;
                    return Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: enough
                            ? pal.sage.withValues(alpha: 0.12)
                            : pal.danger.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.rMd),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                              enough
                                  ? Icons.savings_outlined
                                  : Icons.error_outline,
                              size: 17,
                              color: enough ? pal.sage : pal.danger),
                          const SizedBox(width: 8),
                          Text(
                            enough
                                ? 'Change due: ${money(change)}'
                                : 'Not enough — short by ${money(-change)}',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: enough ? pal.sage : pal.danger),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
          const SizedBox(height: 22),
          PressableScale(
            child: FilledButton(
              style: AppTheme.primaryButton(context),
              onPressed: _canComplete
                  ? () {
                      final Sale sale = store.checkout(_method);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                            builder: (_) => SuccessScreen(sale: sale)),
                      );
                    }
                  : null,
              child: const Text('Complete sale'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(BuildContext context, String label, double amount) {
    final Pal pal = Pal.of(context);
    return PressableScale(
      pressedScale: 0.92,
      child: ActionChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: pal.ink)),
        backgroundColor: pal.surface,
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: pal.border),
        onPressed: () {
          setState(() {
            _received.text = amount.round().toString();
          });
        },
      ),
    );
  }
}
