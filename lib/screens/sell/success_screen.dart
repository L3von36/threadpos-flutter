import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/motion.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(),
              PopIn(
                begin: 0.4,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                      color: pal.sage, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 16),
              StaggerIn(
                index: 1,
                child: Text('Sale complete',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: pal.ink)),
              ),
              const SizedBox(height: 4),
              StaggerIn(
                index: 2,
                child: Text(
                    'Receipt #${sale.id} · ${clockLabel(sale.time)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: pal.muted)),
              ),
              const SizedBox(height: 20),
              StaggerIn(
                index: 3,
                dy: 18,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: pal.surface,
                    borderRadius: BorderRadius.circular(AppTheme.rLg),
                    border: Border.all(color: pal.border),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                              '${paymentMethodLabel(sale.method)} · ${sale.itemCount} item(s)',
                              style: TextStyle(
                                  fontSize: 12, color: pal.muted)),
                          Text(money(sale.total),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: pal.accent)),
                        ],
                      ),
                      const SizedBox(height: 9),
                      ...sale.lines.map(
                        (SaleLine l) => Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                    '${l.name}${l.size.isEmpty ? '' : ' · ${l.size}'} × ${l.qty}',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: pal.ink)),
                              ),
                              Text(money(l.lineTotal),
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: pal.ink)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              PressableScale(
                child: FilledButton(
                  style: AppTheme.primaryButton(context),
                  onPressed: () => Navigator.of(context).popUntil(
                      (Route<dynamic> r) => r.isFirst),
                  child: const Text('Back to register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
